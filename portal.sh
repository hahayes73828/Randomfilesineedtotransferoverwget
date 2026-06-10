#!/bin/sh
# ==============================================================================
# MicroPortal v2 - Multi-Button Captive Portal for TP-Link WR841N (< 3KB)
# ==============================================================================

CLIENT_IP="$REMOTE_ADDR"
CLIENT_MAC=$(ip neigh show | grep "$CLIENT_IP" | awk '{print $5}')
[ -z "$CLIENT_MAC" ] && CLIENT_MAC=$(arp -an | grep "($CLIENT_IP)" | awk '{print $4}')

# Function to dynamically whitelist the device on the firewall
whitelist_device() {
    if [ -n "$CLIENT_MAC" ]; then
        if command -v iptables >/dev/null 2>&1; then
            # Insert at the top of PREROUTING to bypass the redirect trap
            iptables -t nat -I PREROUTING -m mac --mac-source "$CLIENT_MAC" -j ACCEPT
        else
            nft add rule inet fw4 prerouting mac saddr "$CLIENT_MAC" accept 2>/dev/null
        fi
    fi
}

# Process the Form Submission
if [ "$REQUEST_METHOD" = "POST" ]; then
    # Read the POST body to see which button was pressed
    read -r POST_DATA
    action=$(echo "$POST_DATA" | grep -o 'action=[^&]*' | cut -d= -f2)

    whitelist_device

    echo "Content-type: text/html"
    echo ""
    echo "<html><head>"
    
    if [ "$action" = "hijack" ]; then
        # Switch 2 Hijack: Force immediate redirect to Google
        echo "<meta http-equiv='refresh' content='0;url=http://google.com'>"
        echo "</head><body style='background:#111; color:#fff; font-family:sans-serif; text-align:center; padding-top:50px;'>"
        echo "<h2>Hijack Triggered!</h2><p>Loading Google...</p>"
    else
        # Standard Connect: Just unblock internet access
        echo "</head><body style='background:#111; color:#fff; font-family:sans-serif; text-align:center; padding-top:50px;'>"
        echo "<h2 style='color:#4caf50;'>Connected!</h2><p>You now have full internet access.</p>"
    fi
    
    echo "</body></html>"
    exit 0
fi

# Serve the Split-Button Splash Page
echo "Content-type: text/html"
echo ""
echo "<html><head><title>Network Login</title><meta name='viewport' content='width=device-width, initial-scale=1.0'></head>"
echo "<body style='font-family:sans-serif; text-align:center; background:#1e1e1e; color:#fff; padding:20px;'>"
echo "  <div style='max-width:360px; margin:40px auto; background:#2d2d2d; padding:25px; border-radius:12px; box-shadow:0 4px 15px rgba(0,0,0,0.6); border: 1px solid #444;'>"
echo "    <h2 style='margin-bottom:5px; color:#eaeaea;'>OpenWrt Portal</h2>"
echo "    <p style='font-size:12px; color:#888; margin-top:0;'>MAC: ${CLIENT_MAC:-Unknown}</p>"
echo "    <hr style='border:0; border-top:1px solid #444; margin:20px 0;'>"
echo "    "
# Button 1: Standard Internet Access
echo "    <form method='POST' action='/cgi-bin/portal.sh'>"
echo "      <input type='hidden' name='action' value='connect'>"
echo "      <input type='submit' value='Connect' style='background:#007acc; color:white; border:none; padding:14px; font-size:16px; font-weight:bold; border-radius:6px; cursor:pointer; width:100%; margin-bottom:15px; transition:0.2s;'>"
echo "    </form>"
echo "    "
# Button 2: Web Hijack straight to Google
echo "    <form method='POST' action='/cgi-bin/portal.sh'>"
echo "      <input type='hidden' name='action' value='hijack'>"
echo "      <input type='submit' value='Switch 2 Web Hijack' style='background:#e040fb; color:black; border:none; padding:14px; font-size:16px; font-weight:bold; border-radius:6px; cursor:pointer; width:100%; transition:0.2s;'>"
echo "    </form>"
echo "  </div>"
echo "</body></html>"
