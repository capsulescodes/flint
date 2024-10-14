import s from "fs";
process.env.INIT_CWD === process.cwd() && process.exit();
const e = `${process.env.INIT_CWD}/.flint`, c = `${process.env.INIT_CWD}/node_modules/flint-js/.flint`;
!s.existsSync(e) && s.existsSync(c) && s.cpSync(c, e, { recursive: !0 });
