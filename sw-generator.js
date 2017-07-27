/* eslint-disable */
const fs = require("fs");
const _ = require("lodash");
const exclude = ["sw.js", "sw-toolbox.js", "manifest.*", "favicon.ico"];
const recursive = require("recursive-readdir");
const dir = "dist/";

//read all files that have to be precashed
recursive("./" + dir, exclude, (err, files) => {
  const fileList = files.map(file => file.replace(dir, ""));

  //read SW template
  const swTemplate = fs.readFileSync("./src/sw-template.js", "utf8");
  const swCompile = _.template(swTemplate);
  const sw = swCompile({
    precache: '"' + fileList.join('","') + '"',
    hash: new Date().getTime()
  });

  //copy SW-toolbox script
  fs
    .createReadStream("./node_modules/sw-toolbox/sw-toolbox.js")
    .pipe(fs.createWriteStream("./" + dir + "sw-toolbox.js"));

  //save SW file
  fs.writeFileSync("./" + dir + "sw.js", sw, "utf8");

  console.log("SW generated...");
});
