const pool = require("../config/db");
const { logger } = require("../logs/winston");

let shopdb = {};




shopdb.showCounterTicket = (counter_id) => {
    console.log('====================================');
    console.log(counter_id);
    console.log('====================================');
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT ct.counter_ticket_id, ct.counter_id, ct.ticket_id, ct.assigned_timestamp, ct.served,
        t.branch_id,t.token_number, t.service_id, t.customer_id, t.generated_time, t.status, t.queue_position, t.dispenser_id
 FROM counter_ticket ct
 JOIN ticket t ON ct.ticket_id = t.ticket_id
 WHERE ct.served = $1 AND ct.counter_id = $2;
    
        `, [false, counter_id], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
module.exports = shopdb