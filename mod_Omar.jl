"""
Omar's implementation
"""

using TOML

parameters_file_name="parameters_Omar.toml"
# print(isfile(parameters_file_name))

parameters=TOML.parsefile(parameters_file_name)

locations=parameters["locations"]

for (location,quantities) in locations
    print(quantities["latitude"])

end 