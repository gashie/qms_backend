const pool = require("../config/db");
const { logger } = require("../logs/winston");

let shopdb = {};




shopdb.findUniqueCustomer = (customer_id) => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT * FROM customers
        WHERE email = $1 OR phone_number = $1;;
    
        `, [customer_id], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};

module.exports = shopdb