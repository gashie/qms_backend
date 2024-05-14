const pool = require("../config/db");
const { logger } = require("../logs/winston");

let shopdb = {};




shopdb.GenerateTicket = (branch_acronym,branch_id,service_id,customer_id,status,dispenser_id,form_id) => {
    return new Promise((resolve, reject) => {
        pool.query(`SELECT generate_ticket('${branch_acronym}','${branch_id}','${service_id}','${customer_id}','${status}','${dispenser_id}','${form_id}')`, [], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
module.exports = shopdb