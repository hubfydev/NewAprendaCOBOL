const express = require("express");
const { spawn } = require("child_process");

const app = express();
app.use(express.json());

app.post("/run-cobol", (req, res) => {
  const cobol = spawn("../hello-cobol/hello", []);

  let output = "";
  let error = "";

  cobol.stdout.on("data", data => {
    output += data.toString();
  });

  cobol.stderr.on("data", data => {
    error += data.toString();
  });

  cobol.on("close", code => {
    res.json({
      exitCode: code,
      output,
      error
    });
  });
});

app.listen(3000, () => {
  console.log("API Aprenda COBOL rodando em http://localhost:3000");
});

