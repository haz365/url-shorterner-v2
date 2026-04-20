// ─── Imports ─────────────────────────────────────────────────
const express    = require('express');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
  UpdateCommand
} = require('@aws-sdk/lib-dynamodb');
const { nanoid } = require('nanoid');

// ─── App setup ───────────────────────────────────────────────
const app = express();

// Parse incoming JSON request bodies
app.use(express.json());

// Also parse form submissions from the browser
app.use(express.urlencoded({ extended: true }));

const PORT       = process.env.PORT        || 3000;
const AWS_REGION = process.env.AWS_REGION  || 'eu-west-2';
const TABLE_NAME = process.env.DYNAMO_TABLE || 'url-mappings';

// ─── AWS SDK setup ───────────────────────────────────────────
const client    = new DynamoDBClient({ region: AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

// ─── Helper: generate HTML page ──────────────────────────────
const generateHTML = (data = {}) => `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>URL Shortener</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #0f0f1a;
      color: #ffffff;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }

    .card {
      background: #1a1a2e;
      border: 1px solid #2a2a4a;
      border-radius: 24px;
      padding: 48px;
      max-width: 580px;
      width: 100%;
      text-align: center;
    }

    .logo {
      font-size: 48px;
      margin-bottom: 16px;
    }

    h1 {
      font-size: 2rem;
      font-weight: 700;
      margin-bottom: 8px;
      background: linear-gradient(135deg, #667eea, #a78bfa);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }

    .subtitle {
      color: #8888aa;
      margin-bottom: 32px;
      font-size: 0.95rem;
    }

    .form-group {
      display: flex;
      gap: 10px;
      margin-bottom: 24px;
    }

    input {
      flex: 1;
      background: #0f0f1a;
      border: 1px solid #2a2a4a;
      border-radius: 10px;
      padding: 12px 16px;
      color: #ffffff;
      font-size: 0.95rem;
      outline: none;
    }

    input:focus { border-color: #667eea; }
    input::placeholder { color: #8888aa; }

    button {
      background: linear-gradient(135deg, #667eea, #764ba2);
      color: white;
      border: none;
      border-radius: 10px;
      padding: 12px 24px;
      font-size: 0.95rem;
      font-weight: 600;
      cursor: pointer;
      white-space: nowrap;
    }

    button:hover { opacity: 0.85; }

    .result {
      background: #0f0f1a;
      border: 1px solid #2a2a4a;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 24px;
      text-align: left;
    }

    .result-label {
      font-size: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: #8888aa;
      margin-bottom: 8px;
    }

    .result-url {
      color: #a78bfa;
      font-size: 1rem;
      font-weight: 600;
      word-break: break-all;
    }

    .copy-btn {
      display: inline-block;
      margin-top: 10px;
      background: #2a2a4a;
      border: none;
      border-radius: 8px;
      padding: 6px 14px;
      color: #a78bfa;
      font-size: 0.8rem;
      cursor: pointer;
    }

    .error {
      background: #2a1a1a;
      border: 1px solid #4a2a2a;
      border-radius: 12px;
      padding: 16px;
      color: #ff8888;
      font-size: 0.9rem;
      margin-bottom: 24px;
    }

    .badges {
      display: flex;
      gap: 8px;
      justify-content: center;
      flex-wrap: wrap;
    }

    .badge {
      background: #2a2a4a;
      border: 1px solid #3a3a5a;
      border-radius: 20px;
      padding: 6px 14px;
      font-size: 0.8rem;
      color: #a78bfa;
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .dot {
      width: 6px;
      height: 6px;
      background: #22c55e;
      border-radius: 50%;
      animation: pulse 2s infinite;
    }

    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.4; }
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">🔗</div>
    <h1>URL Shortener</h1>
    <p class="subtitle">Paste a long URL and get a short one instantly</p>

    ${data.error ? `<div class="error">⚠️ ${data.error}</div>` : ''}

    ${data.shortUrl ? `
    <div class="result">
      <div class="result-label">Your short URL</div>
      <div class="result-url">${data.shortUrl}</div>
      <button class="copy-btn"
        onclick="navigator.clipboard.writeText('${data.shortUrl}')">
        📋 Copy
      </button>
    </div>
    ` : ''}

    <form class="form-group" action="/shorten" method="POST">
      <input
        type="url"
        name="url"
        placeholder="https://example.com/very/long/url"
        required
      />
      <button type="submit">Shorten</button>
    </form>

    <div class="badges">
      <span class="badge"><span class="dot"></span>ECS Fargate</span>
      <span class="badge"><span class="dot"></span>DynamoDB</span>
      <span class="badge"><span class="dot"></span>Terraform</span>
    </div>
  </div>
</body>
</html>
`;

// ─── Routes ──────────────────────────────────────────────────

// Health check — ALB hits this every 30 seconds
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Main page — shows the URL shortener form
app.get('/', (req, res) => {
  res.setHeader('Content-Type', 'text/html');
  res.send(generateHTML());
});

// Shorten a URL — handles both form and API requests
app.post('/shorten', async (req, res) => {
  try {
    // Get URL from either JSON body or form submission
    const url = req.body.url;

    // Basic validation
    if (!url) {
      return res.status(400)
        .setHeader('Content-Type', 'text/html')
        .send(generateHTML({ error: 'Please provide a URL' }));
    }

    // Generate a random 6 character short code e.g. "abc123"
    const code = nanoid(6);

    // Store the mapping in DynamoDB
    await docClient.send(new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        code,
        url,
        created_at: new Date().toISOString(),
        visits: 0
      }
    }));

    // Build the short URL using the request host
    const host     = req.headers.host;
    const shortUrl = `http://${host}/${code}`;

    // If API request → return JSON
    // If browser form → return HTML
    const isAPI = req.headers['content-type'] === 'application/json';

    if (isAPI) {
      return res.json({ code, short_url: shortUrl, url });
    }

    res.setHeader('Content-Type', 'text/html');
    res.send(generateHTML({ shortUrl }));

  } catch (err) {
    console.error('Error shortening URL:', err);
    res.status(500)
      .setHeader('Content-Type', 'text/html')
      .send(generateHTML({ error: 'Could not shorten URL: ' + err.message }));
  }
});

// Redirect — when someone visits a short code
app.get('/:code', async (req, res) => {
  try {
    const { code } = req.params;

    // Look up the code in DynamoDB
    const result = await docClient.send(new GetCommand({
      TableName: TABLE_NAME,
      Key: { code }
    }));

    // If code not found → show 404
    if (!result.Item) {
      return res.status(404)
        .setHeader('Content-Type', 'text/html')
        .send(generateHTML({ error: `Short code "${code}" not found` }));
    }

    // Increment the visit counter
    await docClient.send(new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { code },
      UpdateExpression: 'ADD visits :inc',
      ExpressionAttributeValues: { ':inc': 1 }
    }));

    // Redirect to the original URL
    res.redirect(301, result.Item.url);

  } catch (err) {
    console.error('Error redirecting:', err);
    res.status(500)
      .setHeader('Content-Type', 'text/html')
      .send(generateHTML({ error: 'Could not redirect: ' + err.message }));
  }
});

// ─── Export ───────────────────────────────────────────────────
module.exports = app;