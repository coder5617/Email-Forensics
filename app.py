from flask import Flask, render_template, request
import email.parser
import email.utils
import re
import datetime
import requests
import dns.resolver
import dns.exception
import ipaddress  # Added for IP validation

app = Flask(__name__)

def is_valid_ip(ip):
    """Validate if string is a valid IP address"""
    try:
        ipaddress.ip_address(ip)
        return True
    except ValueError:
        return False

def is_private_ip(ip):
    """Check if IP is private or loopback"""
    if not ip:
        return True
    try:
        ip_obj = ipaddress.ip_address(ip)
        return ip_obj.is_private or ip_obj.is_loopback
    except ValueError:
        return True

def is_blacklisted(ip):
    """Check if IP is blacklisted on Spamhaus"""
    if not ip or is_private_ip(ip):
        return False
    try:
        parts = ip.split('.')
        reversed_ip = '.'.join(reversed(parts))
        query = f'{reversed_ip}.zen.spamhaus.org'
        dns.resolver.resolve(query, 'A')
        return True
    except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
        return False
    except:
        return False

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        header_text = request.form['header']
        parser = email.parser.Parser()
        msg = parser.parsestr(header_text)

        headers_found = {k: v for k, v in msg.items()}

        # Extract domains
        from_header = msg.get('From', '')
        from_domain = email.utils.parseaddr(from_header)[1].split('@')[-1] if from_header else ''
        return_path = msg.get('Return-Path', '')
        rp_domain = email.utils.parseaddr(return_path)[1].split('@')[-1] if return_path else ''

        # Alignment checks
        spf_aligned = from_domain == rp_domain if rp_domain else False
        dkim_signature = msg.get('DKIM-Signature', '')
        dkim_aligned = False
        if dkim_signature:
            d_match = re.search(r'\bd=([^;]+)', dkim_signature)
            if d_match:
                d_domain = d_match.group(1)
                dkim_aligned = from_domain == d_domain

        # Authentication results parsing
        auth_results = msg.get('Authentication-Results', '')
        spf_result = re.search(r'spf=([a-zA-Z]+)', auth_results)
        spf_status = spf_result.group(1) if spf_result else 'none'
        spf_authenticated = spf_status == 'pass'
        dkim_result = re.search(r'dkim=([a-zA-Z]+)', auth_results)
        dkim_status = dkim_result.group(1) if dkim_result else 'none'
        dkim_authenticated = dkim_status == 'pass'
        dmarc_result = re.search(r'dmarc=([a-zA-Z]+)', auth_results)
        dmarc_status = dmarc_result.group(1) if dmarc_result else 'none'
        dmarc_compliant = dmarc_status == 'pass'

        # Extract SPF info from auth (detailed)
        spf_info = re.search(r'spf=[^;]+(?:;[^;]+)*', auth_results).group(0) if re.search(r'spf=[^;]+(?:;[^;]+)*', auth_results) else ''

        # DNS lookups for authentication records
        dmarc_txt = ''
        try:
            dmarc_txt = dns.resolver.resolve(f'_dmarc.{from_domain}', 'TXT')[0].strings[0].decode('utf-8')
        except:
            pass

        spf_txt = ''
        try:
            for txt in dns.resolver.resolve(rp_domain, 'TXT'):
                txt_str = txt.strings[0].decode('utf-8')
                if txt_str.startswith('v=spf1'):
                    spf_txt = txt_str
                    break
        except:
            pass

        dkim_info = ''
        if dkim_signature:
            dkim_info = dkim_signature
        else:
            dkim_info = 'No aligned DKIM-Signature for the message to be considered aligned.'

        # Process relay information
        received_list = msg.get_all('Received', [])
        relays = []
        for idx, rec in enumerate(reversed(received_list), 1):
            from_match = re.search(r'from\s+(.+?)\s+by', rec, re.IGNORECASE | re.DOTALL)
            from_part = from_match.group(1).strip() if from_match else ''
            by_match = re.search(r'by\s+(.+?)\s+(with|id|;|$)', rec, re.IGNORECASE | re.DOTALL)
            by_part = by_match.group(1).strip() if by_match else ''
            with_match = re.search(r'with\s+(.+?)\s+(id|;|$)', rec, re.IGNORECASE | re.DOTALL)
            with_part = with_match.group(1).strip() if with_match else ''
            time_match = re.search(r';\s*(.+)$', rec)
            time_str = time_match.group(1).strip() if time_match else ''
            time_dt = email.utils.parsedate_to_datetime(time_str) if time_str else None

            # Improved IP extraction using better regex for IPv4 and IPv6
            ipv4_pattern = r'(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'
            ipv6_pattern = r'(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))'
            pattern = r'\[?(' + ipv4_pattern + r'|' + ipv6_pattern + r')\]?'
            ips = re.findall(pattern, from_part)
            hop_ip = ips[-1] if ips else ''
            blacklist = is_blacklisted(hop_ip)

            relays.append({
                'hop': idx,
                'from': from_part,
                'by': by_part,
                'with': with_part,
                'time_dt': time_dt,
                'time': time_dt.strftime('%m/%d/%Y %I:%M:%S %p') if time_dt else '',
                'delay': 0,
                'blacklist': not blacklist,
                'ip': hop_ip
            })

        # Adaptive order: if the first time delta is negative, reverse the relays to ensure increasing times
        if len(relays) > 1 and relays[0]['time_dt'] and relays[1]['time_dt'] and (relays[1]['time_dt'] - relays[0]['time_dt']).total_seconds() < 0:
            relays = list(reversed(relays))
            for idx, r in enumerate(relays, 1):
                r['hop'] = idx  # Reassign hop numbers after reversal

        # Calculate delays using datetime objects (preserves timezone awareness and accuracy)
        total_delay = 0
        for i in range(1, len(relays)):
            if relays[i-1]['time_dt'] and relays[i]['time_dt']:
                delta = (relays[i]['time_dt'] - relays[i-1]['time_dt']).total_seconds()
                relays[i]['delay'] = max(delta, 0)  # Set to 0 if negative (clock skew)
                total_delay += relays[i]['delay']

        # Ensure at least one relay has a non-zero delay for visualization
        if total_delay == 0 and relays:
            # If all delays are 0, set a minimal delay for visualization purposes
            for relay in relays:
                relay['delay'] = 0.1  # Minimal delay for visualization
            total_delay = len(relays) * 0.1

        # Sender IP extraction with improved regex to handle "sender IP is" or "client-ip="
        sender_ip = None
        ip_match = re.search(r'(?:sender\s*ip\s*is|client-ip=)\s*([\[\(]?[\d\.:a-fA-F]+[\]\)]?)', auth_results, re.IGNORECASE)
        if ip_match:
            candidate = ip_match.group(1).strip('[]()')
            if is_valid_ip(candidate):
                sender_ip = candidate
        if not sender_ip or is_private_ip(sender_ip):
            for relay in relays:
                if relay['ip'] and is_valid_ip(relay['ip']) and not is_private_ip(relay['ip']):
                    sender_ip = relay['ip']
                    break

        # Get IP information from IPInfo API
        ip_info = {}
        if sender_ip:
            try:
                response = requests.get(f'https://ipinfo.io/{sender_ip}/json', timeout=5)
                if response.ok:
                    ip_info = response.json()
                else:
                    ip_info = {'error': 'Unable to fetch IP info', 'status': response.status_code}
            except requests.exceptions.Timeout:
                ip_info = {'error': 'Request timed out'}
            except Exception as e:
                ip_info = {'error': f'Request failed: {str(e)}'}

        return render_template('results.html', 
                               headers_found=headers_found, 
                               dmarc_compliant=dmarc_compliant, 
                               spf_aligned=spf_aligned,
                               spf_authenticated=spf_authenticated, 
                               dkim_aligned=dkim_aligned, 
                               dkim_authenticated=dkim_authenticated,
                               dmarc_txt=dmarc_txt, 
                               spf_txt=spf_txt, 
                               dkim_info=dkim_info, 
                               spf_status=spf_status, 
                               dkim_status=dkim_status,
                               dmarc_status=dmarc_status, 
                               relays=relays, 
                               total_delay=total_delay, 
                               ip_info=ip_info, 
                               sender_ip=sender_ip,
                               spf_info=spf_info, 
                               auth_results=auth_results)

    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
