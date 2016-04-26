class Bulletin < ActiveRecord::Base
  def posted_date
    posted_on.strftime("%d %b %Y")
  end
end
public
def update_bulletin
    base_uri = 'https://mmu-hub.firebaseio.com/'
    firebase = Firebase::Client.new(base_uri)

    print "PERFORMING CRON JOB \n"
    agent = Mechanize.new
    agent.keep_alive = true
    agent.agent.http.retry_change_requests = true
    page = agent.get("https://online.mmu.edu.my/index.php")
    form = page.form
    bulletins = []
    form.form_loginUsername =  ENV['STUDENT_ID']
    form.form_loginPassword = ENV['PORTAL_PASSWORD']
    print "WOW"
    page = agent.submit(form)
    page = agent.get("https://online.mmu.edu.my/bulletin.php")
    bulletin_number = 1

    while !page.parser.xpath("//*[@id='tabs-1']/div[#{bulletin_number}]").empty? and bulletin_number <= 100
      url = page.parser.xpath("//*[@id='tabs-1']/div[#{bulletin_number}]/p/a/@href").text
      unless (Bulletin.find_by_url(url))
        print "EXECUTING " + bulletin_number.to_s + "\n"
        bulletin_post = page.parser.xpath("//*[@id='tabs-1']/div[#{bulletin_number}]")
        bulletin = Bulletin.new
        bulletin.title = bulletin_post.xpath("p/a[1]").text

        bulletin_details = bulletin_post.xpath("div/div/text()").text.split("\r\n        ").delete_if(&:empty?)
        bulletin.posted_on = Time.parse(bulletin_details[0].split(" ")[2..5].join(" "))
        bulletin.url = page.parser.xpath("//*[@id='tabs-1']/div[#{bulletin_number}]/p/a/@href").text
        bulletin.expired_on = Time.parse(bulletin_details[1].split(" : ")[1])
        bulletin.author = bulletin_details[2].split(" : ")[1].delete("\t")
        bulletin.contents = bulletin_post.xpath("div/div")
        if (bulletin.contents.include?('<a href="'))
          bulletin.contents.gsub!('href="', '<a href="https://online.mmu.edu.my/')
        end

        response = firebase.push("bulletin_posts", { 
            title: bulletin.title, datePosted: bulletin.posted_on.to_time.to_i, url: bulletin.url,
             dateExpired: bulletin.expired_on.to_time.to_i, author: bulletin.author, contents: bulletin.contents})
        print "SUCCESSSS????" + response.success?.to_s
        bulletin.save
      end
      bulletin_number = bulletin_number + 1
    end
end
