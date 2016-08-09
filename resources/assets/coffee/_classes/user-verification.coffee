###
# Copyright 2015-2016 ppy Pty. Ltd.
#
# This file is part of osu!web. osu!web is distributed with the hope of
# attracting more community contributions to the core ecosystem of osu!.
#
# osu!web is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License version 3
# as published by the Free Software Foundation.
#
# osu!web is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with osu!web.  If not, see <http://www.gnu.org/licenses/>.
###
class @UserVerification
  clickAfterVerification: null # Used as callback on original action (where login was required)


  constructor: ->
    # $(document).on 'ajax:success', '.js-verification-form', @success
    # $(document).on 'ajax:error', '.js-verification-form', @error

    # $(document).on 'click', '.js-user-link', @showOnClick
    # $(document).on 'click', '.js-login-required--click', @showToContinue

    # $(document).on 'ajax:error', @showOnError
    # $(document).on 'ready turbolinks:load', @showOnLoad
    # $.subscribe 'nav:popup:hidden', @reset

    $(document).on 'keyup', '.js-user-verification--input', @autoSubmit


  autoSubmit: (e) =>
    inputKey = e.currentTarget.value.replace /\s/g, ''
    lastKey = e.currentTarget.dataset.lastKey
    keyLength = parseInt(e.currentTarget.dataset.verificationKeyLength, 10)

    return if keyLength != inputKey.length
    return if inputKey == lastTryKey

    e.currentTarget.dataset.lastKey = inputKey

    $.post document.location.href,
      verification_key: inputKey
    .done (xhr) =>
      console.log 'ok!', xhr
    .error (xhr) =>
      console.log 'error!', xhr



  error: (e, xhr) =>
    e.preventDefault()
    e.stopPropagation()
    $('.js-login-form--error').text(osu.xhrErrorMessage(xhr))


  success: (_event, data) =>
    $('.js-user-header').html data.header
    $('.js-user-header-popup').html data.header_popup
    $.publish 'user:update', data.user.data
    @nav.hidePopup()
    osu.pageChange()

    Turbolinks.clearCache()
    $(document).off '.ujsHideLoadingOverlay'
    LoadingOverlay.show()
    if @clickAfterLogin?
      if @clickAfterLogin.submit
        # plain javascript here doesn't trigger submit events
        # which means jquery-ujs handler won't be triggered
        # reference: https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit
        $(@clickAfterLogin).submit()
      else if @clickAfterLogin.click
        # inversely, using jquery here won't actually click the thing
        # reference: https://github.com/jquery/jquery/blob/f5aa89af7029ae6b9203c2d3e551a8554a0b4b89/src/event.js#L586
        @clickAfterLogin.click()
    else
      osu.reloadPage()


  reset: =>
    @clickAfterLogin = null


  show: (target) =>
    @clickAfterLogin = target


  showOnClick: (e) =>
    e.currentTarget.dataset.navMode ?= 'user'
    @nav.toggleMenu e


  showOnError: (e, xhr) =>
    return unless xhr.status == 401 && xhr.responseJSON?.authentication == 'basic'

    @show e.target


  # for pages which require authentication
  # and being visited directly from outside
  showOnLoad: =>
      return unless window.showVerificationModal

      window.showVerificationModal = null
      @show()
