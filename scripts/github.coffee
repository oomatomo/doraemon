# Description:
#   github
#
# Notes:
#

module.exports = (robot) ->
  github = require("githubot")(robot)
  url = "https://api.github.com/repos/" + process.env.HUBOT_GITHUB_REPO

  # Pull Request を作成する
  createPullRequest = (res, branch_from, branch_to) ->
    body = "## checklist \n" +
           "- [ ] review ok? \n"
    data = {
      "title": branch_from,
      "head": branch_from,
      "base": branch_to,
      "body": body
    }
    github.post url + "/pulls", data, (response) ->
      res.send "pull request: " + response.html_url

  # リリースタグを生成する
  createReleaseTag = (res, new_tag, body) ->
    data = {
      "tag_name": new_tag,
      "target_commitish": "master",
      "name": new_tag,
      "draft": true,
      "body": body
    }
    github.post url + "/releases", data, (response) ->
      res.send "created new release"
      res.send "tag_name: " + new_tag
      res.send "url: " + response.html_url

  robot.respond /create pr (\S*)\s*(\S*)/i, (res) ->
    branch_from = res.match[1]
    branch_to   = res.match[2]
    data = {
      "head": branch_from,
      "base": branch_to
    }
    github.get url + "/pulls", data, (response) ->
      if response.length > 0
        res.send "already exists"
        res.send "url: " + response[0].html_url
      else
        createPullRequest(res, branch_from, branch_to)

  robot.respond /release/i, (res) ->
    # 最新のリリースタグを取得する
    github.get url + "/releases/latest", (response) ->
      latest_tag = response.tag_name
      # v1.0.0 -> v1.0.1
      new_tag = response.tag_name.replace /\d+$/, (n) ->
        return ++n
      # masterと最新のタグ間のコミットの差分を見る
      github.get url + "/compare/" + latest_tag + "...master", (response) ->
        body = "### pull request \n"
        # pull requestでのマージを取得する
        for commit in response.commits
          # Merge pull request #1 from branch
          match = commit.commit.message.match(/Merge pull request (#\d+)/)
          if ! match
            continue
          body += match[1] + "\n"

        body += "### diff \n" + "https://github.com/" +
                process.env.HUBOT_GITHUB_REPO + "/compare/" +
                latest_tag +  "..." + new_tag
        createReleaseTag(res, new_tag, body)
