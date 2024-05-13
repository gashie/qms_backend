const pool = require("../config/db");
const { prepareColumns } = require("../helper/global");
const { logger } = require("../logs/winston");

let shopdb = {};



shopdb.FindServiceForm = (service_id) => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT f.*
FROM public.forms f
JOIN public.service_form_mapping sfm ON f.form_id = sfm.form_id
WHERE sfm.service_id = $1;

    
        `, [service_id], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
shopdb.ListServiceForms = () => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT s.*, f.*,sfm.mapping_id
FROM public.service s
JOIN public.service_form_mapping sfm ON s.service_id = sfm.service_id
JOIN public.forms f ON sfm.form_id = f.form_id;


    
        `, [], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};

module.exports = shopdb