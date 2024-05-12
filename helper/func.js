const path = require("path");
const GlobalModel = require("../model/Global");
const { sendResponse } = require("./utilfunc");
module.exports = {

    autoSaveFile: async (file, folder_name,
        folder_location,
        file_name,
        file_type,
        upload_for,
        uploaded_by) => {


        let fileData = {
            folder_name,
            file_name,
            folder_location,
            file_type,
            upload_for,
            uploaded_by
        }
        let results = await GlobalModel.Create(fileData, 'file_uploads', '');
        file.name = `${results.rows[0].upload_id}${path.parse(file.name).ext}`;
        file.mv(`${folder_location}${file.name}`, async (err) => {
            if (err) {
                console.log(err);
                return sendResponse(res, 0, 200, "Problem file upload", [])
            }
        });
        fileData.file_name = file.name
        return fileData;


    },
}