RSpec.describe '/_user_util_links.html.erb', type: :view do

  before do
    allow(view).to receive(:user_signed_in?).and_return(false)
    allow(view).to receive(:current_user).and_return(nil)
  end

  it 'IU Login should go to CAS' do
    Rails.configuration.authentication_method = "iu"
    render
    puts rendered
    expect(rendered).to have_link "Login To CAS"
  end

  it 'Other login should go to regular login' do
    Rails.configuration.authentication_method = "umich"
    render
    expect(rendered).to have_link 'Login'
  end

end

