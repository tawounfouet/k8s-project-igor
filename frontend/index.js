const express = require('express');
const app = express();
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:5000';

app.get('/', (req, res) => {
  res.send(`
    <h1>Frontend</h1>
    <p>Calling backend at <code>${BACKEND_URL}</code></p>
    <script>
      fetch('${BACKEND_URL}/health')
        .then(resp => resp.text())
        .then(data => document.body.innerHTML += '<p>Backend response: ' + data + '</p>')
        .catch(err => document.body.innerHTML += '<p>Backend error: ' + err + '</p>');
    </script>
  `);
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log('Frontend listening on port ' + port));
