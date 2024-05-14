const asynHandler = require("../../middleware/async");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const { showCounterTicket } = require("../../model/Counter");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");





exports.ListPendingTicket = asynHandler(async (req, res, next) => {
    let userData = req.user;
    let branch_id = userData.branch_info.branch_id


    const tableName = 'ticket';
    const columnsToSelect = []; // Use string values for column names
    const ServiceConditions = [
        { column: 'branch_id', operator: '=', value: branch_id },
        { column: 'status', operator: '=', value: 'Pending' },
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, ServiceConditions)


    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})


exports.ProcessTicket = asynHandler(async (req, res, next) => {
    let userData = req.user;
    let counter_id = userData.userCounters[0].counter_id
    let { process_activity, ticket_id } = req.body

    let counterObject = {
        ticket_id,
        counter_id
    }
    if (process_activity === 'Pick') {
        //push ticket to counter ticket(insert)
        //update ticket status(update)
        let results = await GlobalModel.Create(counterObject, 'counter_ticket', '');
        const runupdate = await GlobalModel.Update({status:'Picked'}, 'ticket', 'ticket_id',ticket_id)

        if (results.rowCount == 1 && runupdate.rowCount == 1) {
            //log and update ticket
            return sendResponse(res, 1, 200, "Record saved", [])
        } else {
            return sendResponse(res, 0, 200, "Sorry, failed to pickup ticket, contact admin", [])

        }

    }
    if (process_activity === 'Serve') {
        //push ticket to counter ticket(insert)
        //update ticket status(update)
        const runupdate = await GlobalModel.Update({status:'Served'}, 'ticket', 'ticket_id',ticket_id)
        const runupdatetwo = await GlobalModel.Update({served:true}, 'counter_ticket', 'ticket_id',ticket_id)

        if (runupdatetwo.rowCount == 1 && runupdate.rowCount == 1) {
            //log and update ticket
            return sendResponse(res, 1, 200, "Record saved", [])
        } else {
            return sendResponse(res, 0, 200, "Sorry, failed to pickup ticket, contact admin", [])

        }

    }
    if (process_activity === 'Close') {
        //push ticket to counter ticket(insert)
        //update ticket status(update)
        const runupdate = await GlobalModel.Update({status:'Closed'}, 'ticket', 'ticket_id',ticket_id)
        const runupdatetwo = await GlobalModel.Update({served:false}, 'counter_ticket', 'ticket_id',ticket_id)

        if (runupdatetwo.rowCount == 1 && runupdate.rowCount == 1) {
            //log and update ticket
            return sendResponse(res, 1, 200, "Record saved", [])
        } else {
            return sendResponse(res, 0, 200, "Sorry, failed to pickup ticket, contact admin", [])

        }

    }
    if (process_activity === 'Transfer') {
        //push ticket to counter ticket(insert)
        //update ticket status(update)
        let results = await GlobalModel.Create(counterObject, 'counter_ticket', '');
        const runupdate = await GlobalModel.Update({status:'Transferred'}, 'ticket', 'ticket_id',ticket_id)

        if (results.rowCount == 1 && runupdate.rowCount == 1) {
            //log and update ticket
            return sendResponse(res, 1, 200, "Record saved", [])
        } else {
            return sendResponse(res, 0, 200, "Sorry, failed to pickup ticket, contact admin", [])

        }

    }
})
exports.ShowCounterServing = asynHandler(async (req, res, next) => {
    let userData = req.user;
    console.log('====================================');
    console.log(userData.userCounters[0]);
    console.log('====================================');
    let counter_id = userData.userCounters[0].counter_id

    let servig = await showCounterTicket(counter_id);
    if (servig.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", {serving:servig.rows})
   
})
