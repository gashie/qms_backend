
// Assuming you have a function to query your database
async function queryServices() {
    // Query your database to get the services
    // This function should return an array of service objects
    // Each service object should have at least the fields mentioned in your data
    // Replace this with your actual database query logic
    return [
        {
            "service_id": "b8b8590e-d361-4fb7-b9e0-9adf092e161f",
            "branch_id": "2c8d24d6-fd4d-4df6-b120-57d727a9bf26",
            "parent_service_id": null,
            "name": "Transfer",
            "label": "Funds Transfer",
            "image_url": "",
            "color": "yellow",
            "text_below": "FT Cash",
            "description": "transfer to account",
            "created_at": "2024-05-09T16:09:10.131Z",
            "updated_at": "2024-05-09T16:08:48.000Z",
            "created_by": null,
            "icon": "fa-fatimes"
        },
        {
            "service_id": "9ba86dba-aa93-4d5d-b427-5ba02f324e05",
            "branch_id": "2c8d24d6-fd4d-4df6-b120-57d727a9bf26",
            "parent_service_id": "b8b8590e-d361-4fb7-b9e0-9adf092e161f",
            "name": "Momo Transfer",
            "label": "Funds Transfer Momo",
            "image_url": "",
            "color": "green",
            "text_below": "FT Cash",
            "description": "transfer to account",
            "created_at": "2024-05-09T16:09:10.131Z",
            "updated_at": "2024-05-09T16:08:48.000Z",
            "created_by": null,
            "icon": "fa-fatimes"
        }
    ];
}

// Recursive function to build the tree structure
async function buildServiceTree(parentId = null) {
    const services = await queryServices();
    const children = services.filter(service => service.parent_service_id === parentId);
    
    // For each child, recursively build its subtree
    for (const child of children) {
        const childId = child.service_id;
        const grandchildren = await buildServiceTree(childId);
        child.children = grandchildren;
    }
    
    return children;
}

// Example usage:
buildServiceTree().then(tree => {
    console.log(tree);
}).catch(error => {
    console.error(error);
});
