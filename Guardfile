guard :livereload do

	# directories %w(app/assets) \
	#  .select{|d| Dir.exists?(d) ? d : UI.warning("Directory #{d} does not exist")}


  # watch(%r{app/views/.+\.(erb|haml|slim)$})
  # watch(%r{app/helpers/.+\.rb})
  # watch(%r{public/.+\.(css|js|html)})
  # watch(%r{config/locales/.+\.yml})

  # Rails Assets Pipeline
  watch(%r{(app|vendor)(/assets/\w+/(.+\.(css|js|html|png|jpg))).*}) { |m| "/assets/#{m[3]}" }
  watch(%r{(app|vendor)(/assets/\w+/(.+)\.(scss))}) { |m| "/assets/#{m[3]}.css" }
end
