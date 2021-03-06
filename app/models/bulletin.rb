class Bulletin < ActiveRecord::Base
  def posted_date
    posted_on.strftime("%d %b %Y")
  end
end
public
def update_bulletin
    base_uri = 'https://mmu-hub-14826.firebaseio.com/'
    firebase = Firebase::Client.new(base_uri,ENV["FIREBASE_SECRET"])
    print "PERFORMING CRON JOB \n"
    agent = Mechanize.new
    agent.keep_alive = true
    agent.agent.http.retry_change_requests = true
    page = agent.get("https://online.mmu.edu.my/index.php")
    form = page.form
    bulletins = []
    form.form_loginUsername = "1141125087"
    form.form_loginPassword = "X134549150"
    page = agent.submit(form)
    page = agent.get("https://online.mmu.edu.my/bulletin.php")
    for bulletin_post in page.parser.xpath("//*[@id='tabs-1']/div")
        url = bulletin_post.xpath("p/a/@href").text
        if Bulletin.find_by_url(url)
            break
        else
            bulletin = Bulletin.new
            bulletin.url = url
            bulletin.title = bulletin_post.xpath("p/a[1]/text()")
            bulletin_details = bulletin_post.xpath("div/div/text()").text.split("\r\n        ").delete_if(&:empty?)
            bulletin.posted_on = Time.parse(bulletin_details[0].split(" ")[2..5].join(" "))
            bulletin.expired_on = Time.parse(bulletin_details[1].split(" : ")[1])
            bulletin.author = bulletin_details[2].split(" : ")[1].delete("\t")
            bulletin.contents = bulletin_post.xpath("div/div").to_s
            if (bulletin.contents.include?('<a href="'))
              bulletin[:contents].gsub!('href="', '<a href="https://online.mmu.edu.my/')
            end
            unique_string = (-1 * bulletin.posted_on.to_time.to_i + bulletin[:url].gsub(/[^\d]/, '').to_i).to_s

            response = firebase.set("bulletin_posts/" + unique_string, { 
                title: bulletin.title, datePosted: bulletin.posted_on.to_time.to_i, url: bulletin.url,
                 dateExpired: bulletin.expired_on.to_time.to_i, author: bulletin.author, contents: bulletin.contents})
            print "SUCCESSSS????" + response.success?.to_s + "\n"
            if response.success?
              bulletin.save
            end
        end
    end
end
