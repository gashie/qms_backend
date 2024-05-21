const asynHandler = require("../../middleware/async");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const { showCounterTicket, listCounterPendintTicket, callCounterPendintTicket } = require("../../model/Counter");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");





exports.ListPendingTicket = asynHandler(async (req, res, next) => {
    let userData = req.user;
    let counter_info = req.counter_info
    let branch_id = userData.branch_info.branch_id



    let results = await listCounterPendintTicket(counter_info.counter_id, branch_id);
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})
exports.CallPendingTicket = asynHandler(async (req, res, next) => {
    let userData = req.user;
    let counter_info = req.counter_info
    let branch_id = userData.branch_info.branch_id



    let results = await callCounterPendintTicket(counter_info.counter_id, branch_id);
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }
    let counterObject = {
        ticket_id:results.rows[0].ticket_id,
        counter_id:results.rows[0].counter_id
    }
    const tableNameTwo = 'submitted_forms';
    const columnsToSelectTwo = []; // Use string values for column names
    const ServiceConditionsTwo = [
        { column: 'submission_id', operator: '=', value: results.rows[0].submission_id },
    ];
    let submitted_forms_result = await GlobalModel.Finder(tableNameTwo, columnsToSelectTwo, ServiceConditionsTwo)
    let ticket_info = {
        ticket:results.rows[0],
        status:'Picked',
        say:`Ticket number ${results.rows[0].token_number} visit counter ${results.rows[0].counter_name}`,
        form:submitted_forms_result.rows
    }
 
    let savecounterticket = await GlobalModel.Create(counterObject, 'counter_ticket', '');
    const runupdate = await GlobalModel.Update({ status: 'Picked' }, 'ticket', 'ticket_id', results.rows[0].ticket_id)
    if (savecounterticket.rowCount == 1 && runupdate.rowCount == 1) {
        //log and update ticket
        return sendResponse(res, 1, 200, `Ticket number ${results.rows[0].token_number} visit counter ${results.rows[0].counter_name}`, ticket_info)
    } else {
        return sendResponse(res, 0, 200, "Sorry, failed to pickup ticket, contact admin", [])

    }
})


exports.ProcessTicket = asynHandler(async (req, res, next) => {
    let userData = req.user;
    let counter_id = req.counter_info.counter_id
    let { process_activity, ticket_id } = req.body

    let counterObject = {
        ticket_id,
        counter_id
    }
    if (process_activity === 'Pick') {
        //push ticket to counter ticket(insert)
        //update ticket status(update)
        let results = await GlobalModel.Create(counterObject, 'counter_ticket', '');
        const runupdate = await GlobalModel.Update({ status: 'Picked' }, 'ticket', 'ticket_id', ticket_id)

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
        const runupdate = await GlobalModel.Update({ status: 'Served' }, 'ticket', 'ticket_id', ticket_id)
        const runupdatetwo = await GlobalModel.Update({ served: true }, 'counter_ticket', 'ticket_id', ticket_id)

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
        const runupdate = await GlobalModel.Update({ status: 'Closed' }, 'ticket', 'ticket_id', ticket_id)
        const runupdatetwo = await GlobalModel.Update({ served: false }, 'counter_ticket', 'ticket_id', ticket_id)

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
        const runupdate = await GlobalModel.Update({ status: 'Transferred' }, 'ticket', 'ticket_id', ticket_id)

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
    let counter_id = req.counter_info.counter_id

    let servig = await showCounterTicket(counter_id);
    if (servig.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", { serving: servig.rows })

})
