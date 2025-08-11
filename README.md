# Email-Forensics

A powerful web-based tool for analyzing email headers to verify authentication, track delivery paths, and identify potential security issues. 
## Features

### 🔐 Authentication Analysis

- **DMARC Compliance Check** - Verifies Domain-based Message Authentication, Reporting & Conformance
- **SPF Validation** - Checks Sender Policy Framework alignment and authentication
- **DKIM Verification** - Validates DomainKeys Identified Mail signatures
- **Real-time DNS Lookups** - Fetches current DMARC, SPF, and DKIM records

### 📊 Delivery Path Analysis

- **Relay Details Table** - Comprehensive information about each hop in the delivery chain
- **Timing Analysis** - Calculates and displays delays between each relay server
- **Blacklist Check** - Verifies if relay IPs are on spam blacklists (Spamhaus)

### 🌐 IP Intelligence

- **Sender IP Detection** - Automatically identifies the originating sender's IP address
- **Geolocation Data** - Provides location, ISP, and organization information via IPInfo API
- **Private IP Filtering** - Identifies and handles private/internal IP addresses appropriately

## Technology Stack

- **Backend**: Python 3.12, Flask
- **Frontend**: HTML5, CSS3 (with CSS Variables), Vanilla JavaScript
- **DNS Operations**: dnspython library
- **IP Geolocation**: IPInfo API
- **Containerization**: Docker & Docker Compose
- **Email Parsing**: Python email.parser module

## Installation

### Prerequisites

- Docker and Docker Compose installed
- Python 3.12+ (for local development)
- Internet connection for DNS lookups and IP geolocation

### Quick Start with Docker

1. Clone the repository:

```bash
git clone https://github.com/coder5617/Email-Forensics.git
cd Email-Forensics
```

2. Build and run with Docker Compose:

```bash
docker-compose up --build
```

3. Access the application:

```
http://localhost:5000
```

### Local Development Setup

1. Create a virtual environment:

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Run the Flask application:

```bash
python app.py
```

## Usage

### Getting Email Headers

#### Gmail

1. Open the email you want to analyze
2. Click the three dots menu (⋮) in the top right
3. Select "Show original"
4. Copy all the header text

#### Outlook/Office 365

1. Open the email in Outlook
2. Click File → Properties
3. Copy the text from "Internet headers"

#### Yahoo Mail

1. Open the email
2. Click "More" (three dots)
3. Select "View raw message"
4. Copy the header portion

#### Apple Mail

1. Open the email
2. Select View → Message → All Headers
3. Copy the displayed headers

### Analyzing Headers

1. Navigate to the application homepage
2. Paste the complete email header into the text area
3. Click "Analyze Header"
4. Review the comprehensive analysis results

## Understanding the Results

### Delivery Information Table

- **Green checkmarks (✅)**: Indicate passed authentication or good status
- **Red X marks (❌)**: Indicate failed authentication or issues
- **Status columns**: Show the actual authentication result (PASS/FAIL/NONE)

### Relay Details

- **Hop**: Sequential number of the relay server
- **Delay**: Time taken at this hop
- **From/By**: Server information for the relay
- **With**: Protocol used for transmission
- **Time**: Timestamp of the relay
- **Blacklist**: Whether the IP is on spam blacklists

## Project Structure

```
email-header-analyzer/
├── app.py                 # Main Flask application
├── requirements.txt       # Python dependencies
├── Dockerfile            # Docker container configuration
├── docker-compose.yml    # Docker Compose orchestration
├── .env                  # Environment variables (create if needed)
├── README.md            # Project documentation
├── templates/           # HTML templates
│   ├── index.html      # Homepage
│   └── results.html    # Analysis results page
└── static/             # Static assets
    └── css/
        └── style.css   # Styling with dark/light themes
```

## Configuration

### Environment Variables

Create a `.env` file in the project root for any sensitive configuration:

```env
# Example environment variables
FLASK_ENV=production
FLASK_DEBUG=False
```

### Customization

#### Theme Colors

Edit the CSS variables in `static/css/style.css`:

- Dark mode colors: `body.dark-mode` section
- Light mode colors: `body.light-mode` section

#### IP Geolocation

The application uses the free IPInfo API. For production use with higher rate limits, consider adding an API key:

```python
response = requests.get(f'https://ipinfo.io/{sender_ip}/json?token=YOUR_API_KEY')
```

## Security Considerations

- The application does not store any email data
- All analysis is performed in-memory
- No authentication data is logged
- Private IP addresses are filtered from geolocation lookups
- Input sanitization prevents XSS attacks
- DNS lookups use secure resolvers

## Troubleshooting

### Common Issues

**Port 5000 Already in Use**

```bash
# Change the port in docker-compose.yml
ports:
  - "5001:5000"
```

**DNS Resolution Failures**

- Ensure your Docker container has internet access
- Check firewall settings for DNS port 53
- Verify DNS resolver configuration

**IPInfo Rate Limiting**

- The free tier allows 50,000 requests/month
- Consider implementing caching for production use
- Add an API key for higher limits

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Acknowledgments

- Inspired by https://mxtoolbox.com/
- IPInfo.io for geolocation services
- Spamhaus for blacklist checking
- Flask community for the excellent framework

## Support

For issues, questions, or suggestions, please open an issue on the GitHub repository.

---

**Note**: This tool is for educational and diagnostic purposes. Always respect privacy and handle email data responsibly.
