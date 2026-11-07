const { Resvg } = require('@resvg/resvg-js'); const fs=require('fs'); const path=require('path');
const P=process.argv[2]; const svg=fs.readFileSync(path.join(P,'branding/svg/notification_icon.svg'),'utf8');
for (const [d,s] of Object.entries({mdpi:24,hdpi:36,xhdpi:48,xxhdpi:72,xxxhdpi:96})) {
  fs.writeFileSync(path.join(P,`android/app/src/main/res/drawable-${d}/ic_notification.png`), new Resvg(svg,{fitTo:{mode:'width',value:s}}).render().asPng());
}
