#!/usr/bin/env python3

"""
Recursively resolve SPF records into IP addresses/networks for use
as a postfix CIDR whitelist (or blacklist).

Replaces the zsh script that did the same with dig and shell parsing,
but handles edge cases properly: CNAME chains, /32 normalization,
IPv6 CIDR, redirect=, the 'a' mechanism with and without domains, etc.

Usage:
    spf2postfix.py [domain ...]

With no arguments, uses a built-in list of trusted domains.
Output goes to stdout in postfix CIDR map format.

Requirements:
    pip install dnspython

Author: Han Boetes <hboetes@gmail.com>
License: MIT
"""

import sys
import ipaddress
import dns.resolver

# Maximum recursion depth to prevent infinite loops
MAX_DEPTH = 10

# Default resolver with a reasonable timeout
resolver = dns.resolver.Resolver()
resolver.timeout = 5
resolver.lifetime = 10

# Default trusted domains (edit to your liking)
DEFAULT_DOMAINS = [
    "google.com",
    "hotmail.com",
    "github.com",
    "paypal.com",
    "linkedin.com",
    "amazon.com",
    "telenet.be",
    "axis-simulation.com",
    "easybank.at",
    "payr.co.at",
    "bike24.net",
    "digid.nl",
    "weblate.org",
]


def get_spf_record(domain: str) -> str | None:
    """Fetch the SPF (v=spf1) TXT record for a domain."""
    try:
        answers = resolver.resolve(domain, "TXT")
    except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN,
            dns.resolver.NoNameservers, dns.exception.Timeout) as e:
        print(f"# WARNING: DNS lookup failed for {domain}: {e}", file=sys.stderr)
        return None

    for rdata in answers:
        # TXT records can be split into multiple strings; join them.
        txt = b"".join(rdata.strings).decode("utf-8", errors="replace")
        if txt.startswith("v=spf1 ") or txt == "v=spf1":
            return txt

    return None


def resolve_a(domain: str) -> list[str]:
    """Resolve A records for a domain, returning IPs only (no CNAMEs)."""
    ips = []
    try:
        for rdata in resolver.resolve(domain, "A"):
            ips.append(str(rdata))
    except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN,
            dns.resolver.NoNameservers, dns.exception.Timeout):
        pass
    return ips


def resolve_aaaa(domain: str) -> list[str]:
    """Resolve AAAA records for a domain."""
    ips = []
    try:
        for rdata in resolver.resolve(domain, "AAAA"):
            ips.append(str(rdata))
    except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN,
            dns.resolver.NoNameservers, dns.exception.Timeout):
        pass
    return ips


def resolve_mx(domain: str) -> list[str]:
    """Resolve MX records, then resolve each MX host to A and AAAA."""
    ips = []
    try:
        mx_records = resolver.resolve(domain, "MX")
    except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN,
            dns.resolver.NoNameservers, dns.exception.Timeout):
        return ips

    for rdata in mx_records:
        mx_host = str(rdata.exchange).rstrip(".")
        ips.extend(resolve_a(mx_host))
        ips.extend(resolve_aaaa(mx_host))

    return ips


def normalize_network(cidr: str) -> str:
    """
    Normalize a CIDR string: strip /32 for IPv4 single hosts,
    and fix host bits set in network addresses (the ipcalc equivalent
    from the original script).
    """
    try:
        net = ipaddress.ip_network(cidr, strict=False)
    except ValueError:
        return cidr  # Return as-is if unparseable; will be caught later.

    if isinstance(net, ipaddress.IPv4Network) and net.prefixlen == 32:
        return str(net.network_address)
    if isinstance(net, ipaddress.IPv6Network) and net.prefixlen == 128:
        return str(net.network_address)

    return str(net)


def recurse_spf(domain: str, depth: int = 0) -> list[str]:
    """
    Recursively parse SPF records for a domain and return a list
    of IP addresses and CIDR networks.
    """
    if depth > MAX_DEPTH:
        print(f"# WARNING: max recursion depth reached at {domain}",
              file=sys.stderr)
        return []

    spf = get_spf_record(domain)
    if spf is None:
        return []

    results = []

    for token in spf.split():
        # Strip qualifiers (+, -, ~, ?)
        if token[0] in "+-~?":
            mechanism = token[1:]
        else:
            mechanism = token

        mechanism_lower = mechanism.lower()

        # ip4:addr or ip4:addr/cidr
        if mechanism_lower.startswith("ip4:"):
            addr = mechanism[4:]
            results.append(normalize_network(addr))

        # ip6:addr or ip6:addr/cidr
        elif mechanism_lower.startswith("ip6:"):
            addr = mechanism[4:]
            results.append(normalize_network(addr))

        # include:domain
        elif mechanism_lower.startswith("include:"):
            inc_domain = mechanism[8:]
            results.extend(recurse_spf(inc_domain, depth + 1))

        # redirect=domain
        elif mechanism_lower.startswith("redirect="):
            redir_domain = mechanism[9:]
            results.extend(recurse_spf(redir_domain, depth + 1))

        # mx (bare) — resolve MX for the current domain
        elif mechanism_lower == "mx":
            results.extend(resolve_mx(domain))

        # mx:otherdomain
        elif mechanism_lower.startswith("mx:"):
            mx_domain = mechanism[3:]
            # Handle optional /cidr suffix: mx:domain/24
            if "/" in mx_domain:
                mx_domain, cidr = mx_domain.rsplit("/", 1)
                for ip in resolve_mx(mx_domain):
                    results.append(normalize_network(f"{ip}/{cidr}"))
            else:
                results.extend(resolve_mx(mx_domain))

        # a (bare) — resolve A/AAAA for the current domain
        elif mechanism_lower == "a":
            results.extend(resolve_a(domain))
            results.extend(resolve_aaaa(domain))

        # a:otherdomain or a:otherdomain/cidr
        elif mechanism_lower.startswith("a:"):
            a_target = mechanism[2:]
            if "/" in a_target:
                a_domain, cidr = a_target.rsplit("/", 1)
                for ip in resolve_a(a_domain):
                    results.append(normalize_network(f"{ip}/{cidr}"))
                for ip in resolve_aaaa(a_domain):
                    results.append(normalize_network(f"{ip}/{cidr}"))
            else:
                results.extend(resolve_a(a_target))
                results.extend(resolve_aaaa(a_target))

        # Skip: v=spf1, all, ~all, -all, ptr, exists, exp=, etc.

    return results


def main():
    if len(sys.argv) > 1:
        # Domains from command line
        domains = sys.argv[1:]
        action = "permit"
        for domain in domains:
            print(f"# {domain}")
            for ip in recurse_spf(domain):
                print(f"{ip} {action}")
    else:
        # Use default domain list
        for domain in DEFAULT_DOMAINS:
            action = "permit"
            print(f"# {domain}")
            for ip in recurse_spf(domain):
                print(f"{ip} {action}")

        # Append blacklist if it exists
        try:
            print("# The rejects from /etc/postfix/blacklist")
            with open("/etc/postfix/blacklist") as f:
                print(f.read(), end="")
        except FileNotFoundError:
            pass


if __name__ == "__main__":
    main()
