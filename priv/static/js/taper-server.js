const path = require("path");
const vm = require("vm");
const webpack = require("webpack");
const memfs = require("memory-fs");
const React = require("react");
const reactDomServer = require("react-dom/server");

const HEADER_LENGTH = 4;

async function compileJsxFile(jsxFile, store) {
  const ctx = vm.createContext({
    window: { taper: { store, React }, taperCompile: true },
    exports: {},
    console: console,
  });

  var compiler = webpack({
    mode: "production",
    entry: `${jsxFile}`,
    output: {
      libraryTarget: "umd",
      umdNamedDefine: true,
      filename: "bundle.js",
      path: "/",
    },
    module: {
      rules: [
        {
          test: /\.jsx?$/,
          exclude: /node_modules/,
          use: {
            loader: "babel-loader",
            options: {
              cwd: path.resolve(process.cwd(), "assets", "node_modules"),
              presets: ["@babel/preset-env", "@babel/preset-react"],
              plugins: ["@babel/plugin-proposal-class-properties"],
            },
          },
        },
      ],
    },
    resolve: {
      modules: [
        process.cwd(),
        path.resolve(process.cwd(), "assets", "js"),
        path.resolve(process.cwd(), "assets", "node_modules"),
        __dirname, // to pick up taper.js
      ],
    },
    resolveLoader: {
      modules: [path.resolve(process.cwd(), "assets", "node_modules")],
    },
  });

  compiler.outputFileSystem = new memfs();

  return new Promise((resolve, reject) => {
    compiler.run((_err, stats) => {
      if (stats.hasWarnings() || stats.hasErrors()) {
        reject(
          `errors = ${stats.toString({ errorDetails: true, warnings: true })}`
        );
      } else {
        var bundle = compiler.outputFileSystem
          .readFileSync("/bundle.js")
          .toString();
        vm.runInContext(bundle, ctx);
        resolve(
          `<div id="<%= @conn.private.taper[:taper_id] || @conn.assigns[:taper_id] || "taper" %>">${reactDomServer.renderToString(
            ctx.exports.default
          )}</div>
          <%= if !(@conn.private.taper[:server_only] || @conn.assigns[:server_only]) do %>
          <script>
            exports = {}
            ${bundle}
            window.taperComponent = exports.default
          </script>
          <% end %>
          `
        );
      }
    });
  });
}

function server(input, output) {
  var state = "start";
  var length = 0;
  var buffer = Buffer.alloc(0);

  sendResult = (result) => {
    const sizeBuffer = Buffer.alloc(HEADER_LENGTH);
    const resultBuffer = Buffer.from(
      JSON.stringify({ type: "response", data: result })
    );
    sizeBuffer.writeInt32BE(resultBuffer.length, 0);
    output.write(sizeBuffer);
    output.write(resultBuffer);
  };

  handleCommand = async ({ type, path, store }) => {
    var result = undefined;

    switch (type) {
      case "compile_jsx_file":
        result = await compileJsxFile(path, store).catch((err) => {
          console.error("ERROR FROM compile", err);
        });
    }

    if (typeof result == "undefined") {
      result = null;
    }
    sendResult(result);
  };

  input.on("data", (chunk) => {
    if (chunk == null || state == "eof") return;

    buffer = Buffer.concat([buffer, chunk]);
    if (state == "start") {
      if (buffer.length < HEADER_LENGTH) return;

      length = buffer.readInt32BE(0);
      if (buffer.length >= length + HEADER_LENGTH) {
        handleCommand(
          JSON.parse(
            buffer.toString("utf8", HEADER_LENGTH, HEADER_LENGTH + length)
          )
        );
        const tmpBuffer = Buffer.alloc(buffer.length - HEADER_LENGTH - length);
        buffer.copy(tmpBuffer, 0, HEADER_LENGTH + length, buffer.length);
        buffer = tmpBuffer;
      } else {
        state = "reading";
      }
      return;
    }

    if (state == "reading") {
      if (buffer.length >= length + HEADER_LENGTH) {
        handleCommand(
          JSON.parse(
            buffer.toString("utf8", HEADER_LENGTH, HEADER_LENGTH + length)
          )
        );
        const tmpBuffer = Buffer.alloc(buffer.length - HEADER_LENGTH - length);
        buffer.copy(tmpBuffer, 0, HEADER_LENGTH + length, buffer.length);
        buffer = tmpBuffer;
        state = "start";
      }
    }
  });

  input.on("end", () => {
    state = "eof";
  });
}

server(process.stdin, process.stdout);
