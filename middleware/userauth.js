const jwt = require("jsonwebtoken");
const dotenv = require("dotenv");
const { DetectDevice, DetectIp, MainDec } = require("../helper/devicefuncs")

const asynHandler = require("./async");
const { sendResponse, CatchHistory } = require("../helper/utilfunc");

dotenv.config({ path: "./config/config.env" });
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");
exports.protectUser = asynHandler(async (req, res, next) => {

    // let device = await DetectDevice(req.headers['user-agent'], req)
    let userIp = DetectIp(req)
    let token;
    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith("Bearer")
    ) {
        token = req.headers.authorization.split(" ")[1];
    } else if (req?.cookies?.tid) {
        token = req?.cookies?.tid;
    }
    //make sure token exists
    if (!token) {
        console.log('no token');
        CatchHistory({ api_response: `User login failed: no token present`, function_name: 'protect-middleware', date_started: systemDate, sql_action: "", event: "Middleware to protect routes", actor: '' }, req)
        return sendResponse(res, 0, 401, 'Sorry Login not successful')
    }

    try {
        //Verify token
        const decoded = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET);
        let tokenInfo = decoded.EncUserInfo
        let decryptToken = MainDec(tokenInfo)

        let checkIp = decryptToken?.devirb
        // let checkDevice = decryptToken?.devcrb
        if (checkIp === userIp) {

            // if (checkIp === userIp && checkDevice === device) {
            req.user = decryptToken;
            console.log('====================================');
            console.log('req.user',req.user);
            console.log('====================================');
            return next()
        } else {
            // console.log('DeviceCheck =', checkDevice === device);
            console.log('IPCheck =', checkIp === userIp);
            console.log('User want to bypass, but access denied');
            CatchHistory({ api_response: `User login failed: device or ip mismatch`, function_name: 'protect-middleware', date_started: systemDate, sql_action: "", event: "Middleware to protect routes", actor: '' }, req)
            return sendResponse(res, 0, 401, 'Sorry Login not successful')


        }

    } catch (error) {
        CatchHistory({ api_response: `User login failed: invalid token or token has expired`, function_name: 'protect-middleware', date_started: systemDate, sql_action: "", event: "Middleware to protect routes", actor: '' }, req)
        return sendResponse(res, 0, 401, 'Sorry Login not successful')
    }
});

