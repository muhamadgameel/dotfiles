local ls = require "luasnip"
local s = ls.snippet
local t = ls.text_node

ls.snippets = {
  all = {
    s(
      "lorem", t(
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce in leo at nisl aliquam molestie. Donec purus ipsum, feugiat ut posuere a, aliquam at est. Phasellus sagittis urna eu velit posuere, sed mattis ante fringilla. In dignissim venenatis arcu, vel accumsan libero venenatis et. Phasellus luctus lacus in justo lacinia, ac ornare urna placerat. Donec at ornare tortor, quis accumsan ex. Aliquam erat volutpat. Morbi viverra blandit lacus sed iaculis. Vestibulum vehicula lobortis tellus. Aliquam accumsan massa nec laoreet dignissim. Etiam dictum turpis sed lacus faucibus, suscipit egestas ipsum volutpat. Ut a ultrices lorem. Nam non commodo erat, a malesuada erat. Ut porttitor ex at enim placerat, non sollicitudin mauris sodales."
      )
    ),
  },
}
