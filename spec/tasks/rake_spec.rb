require 'rails_helper'

require 'rake'

RSpec.describe "Rake tasks", skip: true do
  describe "hyrax:user:list_emails" do
    let!(:user1) { factory_bot_create_user(:user) }
    let!(:user2) { factory_bot_create_user(:user) }

    before do
      load_rake_environment [File.expand_path("../../../lib/tasks/hyrax_user.rake", __FILE__)]
    end

    it "creates a file" do
      run_task "hyrax:user:list_emails"
      expect(File).to exist("user_emails.txt")
      expect(IO.read("user_emails.txt")).to include(user1.email, user2.email)
      File.delete("user_emails.txt")
    end

    it "creates a file I give it" do
      run_task "hyrax:user:list_emails", "abc123.txt"
      expect(File).not_to exist("user_emails.txt")
      expect(File).to exist("abc123.txt")
      expect(IO.read("abc123.txt")).to include(user1.email, user2.email)
      File.delete("abc123.txt")
    end
  end
end
