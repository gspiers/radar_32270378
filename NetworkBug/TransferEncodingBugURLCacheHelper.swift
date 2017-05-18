//
//  TransferEncodingBugURLCacheHelper.swift
//  NetworkBug
//
//  Created by Greg Spiers on 17/05/2017.
//

import Foundation

// This will return a new CachedURLResponse that works around a bug in NSURLSession with gzip transfer-encoding responses.
// This will return the original proposedResponse if it does not need to be modified to work around the bug.
class TransferEncodingBugURLCacheHelper: NSObject {
    
    private static let contentEncodingHeader = "Content-Encoding"
    private static let contentLengthHeader = "Content-Length"
    
    class func fixedCachedUrlResponse(for proposedResponse: CachedURLResponse) -> CachedURLResponse {
        guard let originalResponse = proposedResponse.response as? HTTPURLResponse,
            var headers = originalResponse.allHeaderFields as? [String: String],
            let originalUrl = originalResponse.url else {
                return proposedResponse
        }
        
        // Only fix gzip responses where content-length header doesn't match the data's length that we are about to cache.
        guard let contentEncoding = headers[TransferEncodingBugURLCacheHelper.contentEncodingHeader],
            contentEncoding == "gzip",
            let contentLengthString = headers[TransferEncodingBugURLCacheHelper.contentLengthHeader],
            let contentLength = Int(contentLengthString),
            contentLength != proposedResponse.data.count else {
                return proposedResponse
        }
        
        print("response had a header content-length of: \(contentLength)")
        print("creating new response to cache with header content-length of: \(proposedResponse.data.count)")
        
        headers[TransferEncodingBugURLCacheHelper.contentEncodingHeader] = nil
        headers[TransferEncodingBugURLCacheHelper.contentLengthHeader] = "\(proposedResponse.data.count)"
        
        guard let fixedResponse = HTTPURLResponse(url: originalUrl, statusCode: originalResponse.statusCode, httpVersion: "HTTP/1.1", headerFields: headers) else {
            return proposedResponse
        }
        
        let fixedProposedResponse = CachedURLResponse(response: fixedResponse, data: proposedResponse.data)
        
        return fixedProposedResponse
    }
}
