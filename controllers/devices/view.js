const asynHandler = require("../../middleware/async");
const licenseKey = require('license-key-gen');
const customId = require("custom-id");
const path = require("path");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const { ShowMyDeviceTemplates } = require("../../model/Templates");
const { showBranchCounterTicket } = require("../../model/Counter");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");

exports.OpenDisplayView = asynHandler(async (req, res, next) => {
    // let userData = req.user;

    let template = req.device_template
    if (template && template?.device_type === 'display') {
        
        // Find template carousel
        const tableName = 'fx_rates';
        const columnsToSelect = []; // Use string values for column names
        const conditions = [
            { column: 'template_id', operator: '=', value: template.template_id },
        ];
        let rate = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
        let counter = await showBranchCounterTicket(template.branch_id);

        if (template.template_type === 'carousel') {
            // Find template carousel
            const tableName = 'media_content';
            const columnsToSelect = []; // Use string values for column names
            const conditions = [
                { column: 'dispenser_template_id', operator: '=', value: template.template_id },
            ];
            let carousel = await GlobalModel.Finder(tableName, columnsToSelect, conditions)

            sendResponse(res, 1, 200, "Record Found", { template, carousel: carousel.rows, rate: rate.rows,counter:counter.rows })
        } else {
            sendResponse(res, 1, 200, "Record Found", { template, rate: rate.rows ,counter:counter.rows})
        }
    } else {
        // Find template carousel
        const tableName = 'service';
        const columnsToSelect = []; // Use string values for column names
        const conditions = [
            { column: 'branch_id', operator: '=', value: template?.branch_id },
            { column: 'parent_service_id', operator: 'IS', value: null },
        ];
        let services = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
        if (template?.template_type === 'carousel') {
            // Find template carousel
            const tableName = 'media_content';
            const columnsToSelect = []; // Use string values for column names
            const conditions = [
                { column: 'dispenser_template_id', operator: '=', value: template?.template_id },
            ];
            let carousel = await GlobalModel.Finder(tableName, columnsToSelect, conditions)

            sendResponse(res, 1, 200, "Record Found", { template, carousel: carousel.rows, services: services.rows })
        } else {
            sendResponse(res, 1, 200, "Record Found", { template, services: services.rows })
        }
    }


})
