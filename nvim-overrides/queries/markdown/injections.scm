; Override of nvim-treesitter's bundled markdown injections.scm.
;
; The bundled query resolves a fenced code block's language via the custom
; #set-lang-from-info-string! directive, which crashes on Neovim 0.12 (calls
; a removed TSNode:range() method -- see neovim/neovim#39032 and
; nvim-treesitter/nvim-treesitter#8618). This drops that directive in favor
; of Neovim's built-in @injection.language capture, which achieves the same
; thing without the crash (it just won't resolve short aliases like "js" for
; "javascript" -- exact parser-name matches like "lua", "python", "bash"
; still get injected highlighting).

(fenced_code_block
  (info_string
    (language) @injection.language)
  (code_fence_content) @injection.content)

((html_block) @injection.content
  (#set! injection.language "html")
  (#set! injection.combined)
  (#set! injection.include-children))

((minus_metadata) @injection.content
  (#set! injection.language "yaml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

((plus_metadata) @injection.content
  (#set! injection.language "toml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

([
  (inline)
  (pipe_table_cell)
] @injection.content
  (#set! injection.language "markdown_inline"))
