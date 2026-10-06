return {
  settings = {
    yaml = {
      -- schemastore.nvim supplies the catalogue, so the server's own is off
      schemaStore = { enable = false, url = '' },
      schemas = require('schemastore').yaml.schemas(),
    },
  },
}
