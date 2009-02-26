# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
    # Request from an iPhone or iPod touch? (Mobile Safari user agent)

    def iphone_user_agent?
        request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/(Mobile\/.+Safari)/]
    end

    def deal(price, original)
        if price && original
            100 - (price/original )*100  unless original == 0;
        end
    end

end
