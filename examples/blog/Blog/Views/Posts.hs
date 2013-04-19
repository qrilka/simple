{-# LANGUAGE OverloadedStrings #-}
module Blog.Views.Posts where

import Prelude hiding (id, div, show)
import qualified Prelude as Pre

import Control.Monad
import Data.Maybe
import Text.Blaze.Html5
import Text.Blaze.Html5.Attributes hiding (form, label)

import qualified Blog.Models.Post as P

index :: [P.Post] -> Html
index posts = do
  forM_ posts postPartial

postPartial :: P.Post -> Html
postPartial post = do
  let (Just pid) = P.postId post
  let postUrl = "/posts/" ++ (Pre.show pid)
  article ! class_ "post" $ do
    header $ do
      time $ toHtml $ P.postedAtStr post
      h2 $ a ! href (toValue postUrl) $ toHtml $ P.title post
    div ! class_ "content" $ toHtml $ P.markdownBody post

show post = do
  postPartial post
  div ! class_ "comments content" $ do
    h4 $ "Leave a comment..."
    form $ do
      p $ do
        label ! for "name" $ do
          "Name"
          sup "*"
        "    "
        input ! type_ "text" ! name "name" ! placeholder "Jane Smith"
      p $ do
        label ! for "name" $ do
          "Email"
          sup "*"
        "    "
        input ! type_ "email" ! name "email" ! placeholder "jane@thesmiths.net"
      p $ textarea ! name "comment" $ ""

new :: Html
new =  do
  header $ h2 $ "New Post"
  form ! class_ "content" ! action "/admin/" ! method "post" $ do
    p $ do
      input ! type_ "text" ! name "title" ! id "title" ! placeholder "title"
    p $ do
      textarea ! name "body" ! id "body " ! placeholder "post body..." $ ""
    input ! type_ "submit" ! value "Submit"

edit :: P.Post -> Html
edit post =  do
  header $ h2 $ "Edit Post"
  form ! class_ "content"
       ! action (toValue $ "/admin/" ++ (Pre.show . fromJust $ P.postId post))
       ! method "post" $ do
    input ! type_ "hidden" ! name "_method" ! value "PUT"
    p $ do
      input ! type_ "text" ! name "title" ! id "title"
            ! value (toValue $ P.title post)
    p $ do
      textarea ! name "body" ! id "body " ! rows "10" $ toHtml $ P.body post
    input ! type_ "submit" ! value "Update"
  br
  form ! class_ "content"
       ! action (toValue $ "/posts/" ++ (Pre.show . fromJust $ P.postId post))
       ! method "post" $ do
    input ! type_ "hidden" ! name "_method" ! value "DELETE"
    input ! type_ "submit" ! class_ "destroy" ! value "Delete Post"

listPosts :: [P.Post] -> Html
listPosts posts = do
  header $ h2 $ "Posts"
  div ! class_ "content" $ do
    table ! class_ "admin-posts-list" $ do
      tr $ do
        th "Title"
        th "Posted"
        th " "
        th " "
      forM_ posts $ \post -> do
        let (Just pid) = P.postId post
        let destroyUrl = toValue $ "/admin/" ++ (Pre.show pid)
        let editUrl = toValue $ "/admin/" ++ (Pre.show pid) ++ "/edit"
        tr $ do
          td ! class_ "title "$ toHtml $ P.title post
          td ! class_ "date" $ time $ toHtml $ P.postedAtStr post
          td ! class_ "action" $ a ! href editUrl $ "edit"
          td ! class_ "action" $ do
            form ! action destroyUrl ! method "POST" $ do
              input ! type_ "hidden" ! name "_method" ! value "DELETE"
              input ! type_ "submit" ! value "Delete"
