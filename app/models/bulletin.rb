class Bulletin < ActiveRecord::Base
  def posted_date
    posted_on.strftime("%d %b %Y")
  end
end
public
def update_bulletin
    print "PERFORMING CRON JOB \n"
    agent = Mechanize.new
    page = agent.get("https://online.mmu.edu.my/index.php")
    form = page.form
    bulletins = []
    form.form_loginUsername =  ENV['STUDENT_ID']
    form.form_loginPassword = ENV['PORTAL_PASSWORD']
    page = agent.submit(form)
    page = agent.get("https://online.mmu.edu.my/bulletin.php")
    bulletin_number = 1
    while !page.parser.xpath("//*[@id='tabs-1']/div[#{bulletin_number}]").empty? and bulletin_number <= 20
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
        bulletin.contents = bulletin_post.xpath("div/div/div").text.delete("\t").delete("\r")
        bulletin.save
      end
      bulletin_number = bulletin_number + 1
    end
end
