module Github 
  module ActionHandler
    def button
      ticket = payload.tickets.first
      begin
        response = create_issue(payload.overlay.title, payload.overlay.description)
        html = comment_html(response)
        comment_on_ticket(ticket, html)
      rescue Exception => e
        return [500, e.message]
      end
      [200, "Ticket sent to Github Issues"]
    end
  end
end

module Github
  require 'json'

  class Base < SupportBeeApp::Base
    oauth  :github, :required => true, :oauth_options => {:scope => "user,repo,gist"}
    string :owner, :required => true, :label => 'Owner'
    string :repo, :required => true, :label => 'Repository'

    def validate
      errors[:flash] = ["Please fill in all the required fields"] if settings.owner.blank? or settings.repo.blank?
      errors.empty? ? true : false
    end

    private

    def create_issue(issue_title, description)
      token = settings.oauth_token || settings.token
      response = http_post "https://api.github.com/repos/#{settings.owner}/#{settings.repo}/issues?access_token=#{token}" do |req|
        req.body = {:title => issue_title, :body => description, :labels => ['supportbee']}.to_json
      end
    end

    def comment_html(response)
      "Github Issue created!\n <a href=#{response.body['html_url']}>#{response.body['title']}</a>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end

  end
end
