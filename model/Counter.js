const pool = require("../config/db");
const { logger } = require("../logs/winston");

let shopdb = {};




shopdb.showCounterTicket = (counter_id) => {
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
shopdb.showBranchCounterTicket = (branch_id) => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
        c.name,
        ct.counter_ticket_id, 
        ct.counter_id, 
        ct.ticket_id, 
        ct.assigned_timestamp, 
        ct.served,
        t.token_number,
        t.branch_id, 
        t.service_id, 
        t.customer_id, 
        t.generated_time, 
        t.status, 
        t.queue_position, 
        t.dispenser_id,
        b.name AS branch_name
    FROM 
        counter_ticket ct
    JOIN 
        ticket t ON ct.ticket_id = t.ticket_id
    JOIN 
        counter c ON ct.counter_id = c.counter_id
    JOIN 
        branch b ON c.branch_id = b.branch_id
    WHERE 
        ct.served = $1 AND c.branch_id = $2;
    
        `, [false, branch_id], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
shopdb.counterServices = () => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
        sca.service_counter_assignment_id,
        s.service_id,
        s.name AS service_name,
        c.name AS counter_name,
        b.name AS branch_name
    FROM 
        public.service_counter_assignment sca
    JOIN 
        public.service s ON sca.service_id = s.service_id
    JOIN 
        public.counter c ON sca.counter_id = c.counter_id
    JOIN 
        public.branch b ON c.branch_id = b.branch_id;
    
        `, [], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
shopdb.counterDevices = () => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
        d.device_id,
        d.device_name,
        d.device_type,
        d.ip_address,
        b.name AS branch_name,
        c.name AS counter_name
    FROM 
        public.counter_assignments ca
    JOIN 
        public.devices d ON ca.device_id = d.device_id
    JOIN 
        public.branch b ON ca.branch_id = b.branch_id
    JOIN 
        public.counter c ON ca.counter_id = c.counter_id;
    
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