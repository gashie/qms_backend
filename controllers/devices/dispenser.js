const asynHandler = require("../../middleware/async");
const path = require("path");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const { autoSaveFile } = require("../../helper/func");
const { ShowDeviceTemplates } = require("../../model/Templates");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");

exports.CreateDispenserTemplate = asynHandler(async (req, res, next) => {
    // Assuming template_type is a variable containing the template type ("video" or "image")
    let {template_type} = req.body
    let payload = req.body;

    let background_image = req.files?.background_image
    let background_video = req.files?.background_video
    if (template_type === "video") {
        // Check only background_video
        if (background_video) {
            if (!background_video.mimetype.startsWith("video")) {
                // Handle case where background_video is not a video
                return sendResponse(res, 0, 200, "Sorry,kindly provide video file", [])

            } else {
                // background_video is a video
                let fileData =  await autoSaveFile(background_video,'dispenser','./uploads/videos/dispenser/',background_video.name,background_video.mimetype,'dispenser_template_setup');
  
                payload.background_video = fileData.file_name
                let results = await GlobalModel.Create(payload, 'dispenser_templates', '');
                if (results.rowCount == 1) {
                    return sendResponse(res, 1, 200, "Record saved", [])
                } else {
                    return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])
            
                }
            }
        } else {
            return sendResponse(res, 0, 200, "Sorry,a video file is required for this operation", [])

            // Handle case where background_video is not provided but required
        }
    } else if (template_type === "image") {
        // Check only background_image
        if (background_image) {
            // Define an array of allowed image mimetypes or an array of image file extensions
            const allowedImageTypes = ["image/jpeg", "image/png", "image/gif", /* Add more if needed */];

            // Define a regular expression to match image links (URLs)
            const imageUrlRegex = /^https?:\/\/.+\.(jpeg|jpg|png|gif)$/i;

            if (background_image.mimetype && allowedImageTypes.includes(background_image.mimetype)) {
                // background_image is an image file with a valid mimetype
               
              let fileData =  await autoSaveFile(background_image,'dispenser','./uploads/images/dispenser/',background_image.name,background_image.mimetype,'dispenser_template_setup');
              payload.background_image = fileData.file_name
              let results = await GlobalModel.Create(payload, 'dispenser_templates', '');
              if (results.rowCount == 1) {
                  return sendResponse(res, 1, 200, "Record saved", [])
              } else {
                  return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])
          
              }
          
    
            } else if (background_image.match(imageUrlRegex)) {
                // background_image is a valid image link
                let results = await GlobalModel.Create(payload, 'dispenser_templates', '');
                if (results.rowCount == 1) {
                    return sendResponse(res, 1, 200, "Record saved", [])
                } else {
                    return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])
            
                }
            
            } else {
                return sendResponse(res, 0, 200, "Sorry,kindly provide file or link to the image", [])

                // Handle case where background_image is not a valid image or image link
            }
        } else {
            // Handle case where background_image is not provided but required
        }
    } else {
        // Handle case where template_type is neither "video" nor "image"

        //-1 save template
        let items = background_image
        let results = await GlobalModel.Create(payload, 'dispenser_templates', '');
        if (results.rowCount == 1) {
            let itemCount = background_image.length;
            let isDone = false
            for (const item of items) {
                let fileData =  await autoSaveFile(item,'dispenser','./uploads/images/dispenser/',item.name,item.mimetype,'dispenser_template_setup');
                let media_content ={}
                media_content.content_type ='image'
                media_content.assigned_to =req.body.assigned_to
                media_content.content_url = fileData.file_name
                media_content.dispenser_template_id =results.rows[0].template_id
                let content = await GlobalModel.Create(media_content, 'media_content', '');
                // if (results.rowCount == 1) {
                //     return sendResponse(res, 1, 200, "Record saved", [])
                // } else {
                //     return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])
            
                // }
                if (!--itemCount) {
                    isDone = true;
                    console.log(" => This is the last iteration...");
        
                } else {
                    console.log(" => Still saving data...");
        
                }
            }
            if (isDone) {
                return sendResponse(res, 1, 200, `${items.length} new carousel images added to template with id ${results.rows[0].template_id}`, { template:results.rows[0].template_id })
            }
        } else {
            return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])
    
        }
 
    }


   
})

exports.AssignTemplateToDispenser = asynHandler(async (req, res, next) => {
    /**
 * Create new company.
 * @param {string} device_id -id of the device.
 * @param {string} template_id - uuid of template: .
 * @returns {Object} - Object containing branch details.
 */

    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'display_device_templates', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})


exports.ViewDispenserTemplate = asynHandler(async (req, res, next) => {
    // let userData = req.user;

    const tableName = 'dispenser_templates';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }
    let template_id = results.rows[0].template_id
    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.ViewAssignedTemplate = asynHandler(async (req, res, next) => {
    // let userData = req.user;

    let results = await ShowDeviceTemplates();
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }
    sendResponse(res, 1, 200, "Record Found", results.rows)
})



exports.UpdateDispenserTemplate = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'dispenser_templates', 'template_id', payload.template_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})
exports.UpdateAssignedTemplate = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'display_device_templates', 'device_template_id', payload.device_template_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})

//exchange rate
exports.SetupTemplateExchangeRate = asynHandler(async (req, res, next) => {
    /**
 * Create new company.
 * @param {string} device_id -id of the device.
 * @param {string} template_id - uuid of template: .
 * @returns {Object} - Object containing branch details.
 */

    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'display_device_templates', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})
exports.ViewTemplateExchangeRate = asynHandler(async (req, res, next) => {
    let { template_id } = req.body
    const tableName = 'fx_rates';
    const columnsToSelect = []; // Use string values for column names
    const ServiceConditions = [
        { column: 'template_id', operator: '=', value: template_id },
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, ServiceConditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})
exports.UpdateTemplateExchangeRate = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'fx_rates', 'rate_id', payload.rate_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})