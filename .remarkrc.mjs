import recommended from 'remark-preset-lint-recommended'
import consistent from 'remark-preset-lint-consistent'
import validateLinks from 'remark-validate-links'

export default {
  plugins: [
    recommended,
    consistent,
    [validateLinks, { repository: true }],
    ['remark-lint-maximum-line-length', [120]],
    ['remark-lint-no-heading-punctuation', true],
    ['remark-lint-no-empty-url', true]
  ]
}
