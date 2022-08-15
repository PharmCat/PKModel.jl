(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using PKModel
const UserApp = PKModel
PKModel.main()
