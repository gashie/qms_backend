const jwt = require("jsonwebtoken");
const dotenv = require("dotenv");
const { DetectDevice, DetectIp, MainDec } = require("../helper/devicefuncs")

const asynHandler = require("../middleware/async");
const { sendResponse, CatchHistory } = require("../helper/utilfunc");
const { verifyPermission } = require("../model/Account");

dotenv.config({ path: "./config/config.env" });
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");


exports.checkPermMiddleware = asynHandler(async (req, res, next) => {
    let userData = req.user;
    let user_id = userData?.user_id
    const path = req.path;
    const method = req.method.toUpperCase();

    console.log('====================================');
    console.log(req.user);
    console.log('====================================');
    console.log('====================================');
    console.log(user_id,path,method);
    console.log('====================================');

    const checkAllowed = await verifyPermission(user_id, path, method)
    let isAllowed = checkAllowed.rows[0]
    console.log('====================================');
    console.log(isAllowed);
    console.log('====================================');

    if (!isAllowed) {
        CatchHistory({ payload: JSON.stringify(req.body), api_response: `Sorry, Access denied: You do not have permission to access this route`, function_name: 'checkPermMiddleware', date_started: systemDate, sql_action: "SELECT", event: "VERIFY PERMISSION", actor: userData.user_id }, req)
        return sendResponse(res, 0, 200, `Access denied: You do not have permission to access this route`)
    }
    return next()
});