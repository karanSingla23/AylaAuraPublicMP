//
//  iOS_AylaSDK
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLComponents (AylaNetworks)
/**
 *  The query part of a URL can be parsed into items and values, this method returns te value of a query item. E.g.

 *   NSURLComponents *urlTwoParamEncodedQuery = [NSURLComponents
 componentsWithString:@"http://www.aylanetworks.com/query?param1=value1&encoded1=!%22%C2%B7%24%25%26%2F()%3D%3F*%5E%C2%A8_%3A%3B&encoded2=random%20word%20%C2%A3500%20bank%20%24"];
 *   XCTAssert([[urlTwoParamEncodedQuery ayla_valueForQueryItem:@"param1"] isEqualToString:@"value1"]);
 *   XCTAssert([[urlTwoParamEncodedQuery ayla_valueForQueryItem:@"encoded1"] isEqualToString:@"!\"·$%&/()=?*^¨_:;"]);
 *   XCTAssert([[urlTwoParamEncodedQuery ayla_valueForQueryItem:@"encoded2"] isEqualToString:@"random word £500 bank
 $"]);
 *
 *  @param item The item whose value will be returned.
 *
 *  @return the value of the query item.
 */
- (id)ayla_valueForQueryItem:(NSString *)item;
@end
