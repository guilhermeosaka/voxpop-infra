function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // Check for Identity Service
    if (uri.startsWith('/identity')) {
        request.uri = uri.replace(/^\/identity/, '');
        if (request.uri === '') {
            request.uri = '/';
        }
        request.headers['x-service-name'] = { value: 'voxpop-identity' };
    }
    // Check for Core Service
    else if (uri.startsWith('/core')) {
        request.uri = uri.replace(/^\/core/, '');
        if (request.uri === '') {
            request.uri = '/';
        }
        request.headers['x-service-name'] = { value: 'voxpop-core' };
    }
    // Default to Core if no prefix (catch-all behavior)
    else {
        request.headers['x-service-name'] = { value: 'voxpop-core' };
    }

    return request;
}
