Given('я нахожусь на главной странице') do
  begin
    visit root_path
  rescue => e
    puts "Failed to visit root_path: #{e.message}"
    puts "Rails server might not be running or database might not be available"
    raise e
  end
end

Then('я должен увидеть заголовок {string}') do |title|
  expect(page).to have_content(title)
end

Then('я должен увидеть текущую дату') do
  expect(page).to have_content(Date.current.strftime('%d.%m.%Y'))
end

Then('я должен увидеть секцию прогноза погоды') do
  expect(page).to have_css('section')
end

Then('страница должна иметь правильную структуру') do
  expect(page).to have_css('.bg-gray-50')
  expect(page).to have_css('.max-w-5xl')
  expect(page).to have_css('header')
  expect(page).to have_css('footer')
end

Then('я должен увидеть температуру в градусах Цельсия') do
  expect(page).to have_content('°')
  expect(page).to have_css('.text-lg.font-light.text-gray-900')
  temperature_elements = page.all('.text-lg.font-light.text-gray-900')
  expect(temperature_elements.any? { |el| el.text.match?(/\d+\.?\d*°/) }).to be true
end

Then('я должен увидеть время прогноза') do
  expect(page).to have_css('.text-xs.text-gray-500')
  time_elements = page.all('.text-xs.text-gray-500')
  expect(time_elements.any? { |el| el.text.match?(/\d{1,2}:\d{2}/) }).to be true
end

Then('я должен увидеть данные для города {string}') do |city|
  expect(page).to have_content(I18n.t("cities.#{city}"))
end
