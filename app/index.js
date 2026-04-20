// Entry point — starts the server
const app  = require('./server');
const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`URL Shortener running on port ${PORT}`);
  console.log(`Region: ${process.env.AWS_REGION     || 'eu-west-2'}`);
  console.log(`Table:  ${process.env.DYNAMO_TABLE   || 'url-mappings'}`);
});