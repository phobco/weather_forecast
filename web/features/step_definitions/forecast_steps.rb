Given('я нахожусь на главной странице') do
  visit root_path
end

Then('я должен увидеть заголовок {string}') do |title|
  expect(page).to have_content(title)
end

Then('я должен увидеть текущую дату') do
  expect(page).to have_content(Date.current.strftime('%d.%m.%Y'))
end

Then('я должен увидеть прогноз для Москвы') do
  expect(page).to have_content('Москва')
  expect(page).to have_content(/\d+\.?\d*°/)
end

Then('я должен увидеть прогноз для Санкт-Петербурга') do
  expect(page).to have_content('Санкт-Петербург')
  expect(page).to have_content(/\d+\.?\d*°/)
end
