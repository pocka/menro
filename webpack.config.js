const CspHtmlPlugin = require("csp-html-webpack-plugin");
const HtmlPlugin = require("html-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const LicenseCheckerPlugin = require("license-checker-webpack-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const { EnvironmentPlugin } = require("webpack");

const pkg = require("./package.json");

module.exports = (env, args) => {
  const isDev = args.mode === "development";

  return {
    devtool: isDev ? "cheap-source-map" : false,
    entry: {
      bootstrap: "./src/bootstrap",
    },
    module: {
      rules: [
        // Transform Elm app (through entry point) into JS
        {
          test: /\.elm$/,
          exclude: [/elm-stuff/],
          use: {
            loader: "elm-webpack-loader",
            options: {
              cwd: __dirname,
              debug: isDev,
              // elm-webpack-loader does not support Yarn PnP.
              // Passing the path to `elm` binary via an environment variable.
              pathToElm: process.env.ELM_BIN,
            },
          },
        },
        {
          test: /\.css$/,
          oneOf: [
            // Inject styles into <head> at runtime
            {
              resourceQuery: /runtime/,
              use: ["style-loader", "css-loader"],
            },
            // Load CSS files as external CSS
            {
              use: [MiniCssExtractPlugin.loader, "css-loader"],
            },
          ],
        },
        // Load webfonts as asset
        {
          test: /\.(woff2?|eot|ttf)$/,
          type: "asset",
        },
        // Transpile TypeScript source files
        {
          test: /\.ts$/,
          use: {
            loader: "esbuild-loader",
            options: {
              loader: "ts",
              target: "es2018",
            },
          },
        },
      ],
    },
    resolve: {
      extensions: [".ts", ".js", ".mjs", ".cjs", ".json"],
    },
    optimization: {
      minimize: !isDev,
      minimizer: [
        new TerserPlugin({
          terserOptions: {
            format: {
              comments: false,
            },
          },
          extractComments: false,
        }),
      ],
    },
    plugins: [
      // https://github.com/microsoft/license-checker-webpack-plugin
      new LicenseCheckerPlugin({
        outputFilename: "oss-license.txt",
      }),
      // https://github.com/webpack-contrib/mini-css-extract-plugin
      new MiniCssExtractPlugin(),
      // https://github.com/jantimon/html-webpack-plugin
      new HtmlPlugin({
        template: "./src/index.html",
      }),
      // https://github.com/slackhq/csp-html-webpack-plugin
      new CspHtmlPlugin(
        {
          "script-src": "'self'",
          "style-src": "'self'",
        },
        {
          enabled: !isDev,
        }
      ),
      new EnvironmentPlugin({
        REPOSITORY_URL: pkg.repository.url,
      }),
    ],
  };
};
