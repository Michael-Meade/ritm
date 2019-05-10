require 'ritm'
class Test
    def save_req(url, req, dir)
      puts dir
      f = File.open("/List/#{dir}.txt", "a")
      f << "[================================]\n"
      f << url
      f << req
      f << "[================================]\n"
    end
    def remove_firefox
      dir = Dir["List/*"].sort_by{ |m| m.scan(/\d+/)[0].to_i }.last.gsub("List/", "").to_i
      dir = dir += 1
      Ritm.on_request do |req|
        url = req.request_uri.to_s
        url = url.split("//")[1].split("/")[0]
        puts url
        if not File.foreach("List/blacklistedDomains.txt").grep(/#{url}/)
          puts "URL: #{url}"
          save_req(url, req, dir)
        end
      end
    end
  	def remove_images
      dir = Dir["List/*"].sort_by{ |m| m.scan(/\d+/)[0].to_i }.last.gsub("List/", "").to_i
      dir = dir += 1
      Ritm.on_request do |req|
        url = req.request_uri.to_s
        if not url.include?([".jpg", ".png", ".jpeg", ".PNG", ".gif"])
          save_req(url, req, dir)
        end
      end
    end
    def replace_image(images)
      images = File.read(images)
      Ritm.on_response do |_req, res|
        puts _res
      end
    end
    def body_replace(string, replaceString)
      dir = Dir["List/*"].sort_by{ |m| m.scan(/\d+/)[0].to_i }.last.gsub("List/", "").to_i
      dir = dir += 1
      Ritm.on_response do |_req, res|
          res.body += res.body.to_s.gsub(string, replaceString)
      end
    end
    def save_post
      dir = Dir["List/*"].sort_by{ |m| m.scan(/\d+/)[0].to_i }.last.gsub("List/", "").to_i
      dir = dir += 1
      Ritm.on_request do |req|
        url = req.request_uri.to_s
        post = req.request_method.to_s
        if post == "POST"
          save_req(url, req, dir)
        end 
      end
    end
    def show_domain
      Ritm.on_request do |req| 
        if req.request_uri.to_s.match("tacobell")
          puts req.request_uri
        end
      end
    end
    def change_param(site, param, new_query_string)
      puts new_query_string
      Ritm.on_request do |req|
        if req.request_uri.host.start_with? 'www.google.'
          new_query_string = req.request_uri.query.to_s.gsub(/(?<=^q=|&q=)(((?!&|$).)*)(?=&|$)/, "#{new_query_string}")
          req.request_uri.query = new_query_string
        end
      end
    end
    def inject_js(file="alert.js")
      # needs .js But not js/
      js = File.read("js/" + file)
      Ritm.on_response do |_req, res|
        if  res.body.match ".js"
          res.body += js
        end
      end
    end

end
module Plugins
  class << self
    A = Test.new()
    def inject_js(file)
      A.inject_js(file="alert.js") do |b|
        puts
      end
    end
    def remove_images
      A.remove_images do |b|
        puts
      end
    end
    def regex_body_replace
      A.regex_body_replace do |b|
        puts
      end
    end
    def remove_links
      A.remove_firefox do |b|
        puts 
      end
    end
    def replace_images(file)
      A.replace_image(file) do |b|
        puts
      end
    end
    def change_param(site, param, new_query_string)
      A.change_param(site, param, new_query_string) do |b|
        puts
      end
    end
    def show_domain
      A.show_domain do |b|
        puts
      end
    end
    def save_post
      A.save_post do |b|
        puts
      end
    end
  end
end
