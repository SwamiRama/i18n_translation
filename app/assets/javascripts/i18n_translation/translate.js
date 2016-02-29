// Return elements which are in A but not in arg0 through argn
Array.prototype.diff =
  function() {
    var a1 = this;
    var a = a2 = null;
    var n = 0;
    while (n < arguments.length) {
      a = [];
      a2 = arguments[n];
      var l = a1.length;
      var l2 = a2.length;
      var diff = true;
      for (var i = 0; i < l; i++) {
        for (var j = 0; j < l2; j++) {
          if (a1[i] === a2[j]) {
            diff = false;
            break;
          }
        }
        diff ? a.push(a1[i]) : diff = true;
      }
      a1 = a;
      n++;
    }
    return a.unique();
  };
// Return new array with duplicate values removed
Array.prototype.unique =
  function() {
    var a = [];
    var l = this.length;
    for (var i = 0; i < l; i++) {
      for (var j = i + 1; j < l; j++) {
        // If this[i] is found later in the array
        if (this[i] === this[j])
          j = ++i;
      }
      a.push(this[i]);
    }
    return a;
  };
var source_ids = [];

function googleCallback(response) {
  if (response.error) {
    alert(response.error.message);
    return;
  }
  var result_text = response.data.translations[0].translatedText.gsub(/__(.+)__/, function(match) {
    return '{{' + match[1] + '}}';
  });
  var id = source_ids.shift();
  if (id) {
    Form.Element.setValue(id, result_text);
  }
}

function getGoogleTranslation(id, text, from_language, to_language) {
  source_ids.push(id);
  text = text.replace(/\{\{/, '__').replace(/\}\}/, '__');
  var s = document.createElement('script'),
    api_key = '<%= Translate.api_key %>';
  s.type = 'text/javascript';
  s.src = 'https://www.googleapis.com/language/translate/v2?key=' + api_key + '&source=' +
    from_language + '&target=' + to_language + '&callback=googleCallback&q=' + text;
  document.getElementsByTagName("head")[0].appendChild(s);
}

function bingCallback(text) {
  var id = source_ids.shift();
  if (text && id) {
    var result_text = text.gsub(/__(.+)__/, function(match) {
      return '{{' + match[1] + '}}';
    });
    Form.Element.setValue(id, result_text);
  }
}

function getBingTranslation(id, text, from_language, to_language) {
  source_ids.push(id);
  text = text.replace(/\{\{/, '__').replace(/\}\}/, '__');
  var s = document.createElement("script"),
    app_id = '<%= Translate.app_id %>';
  s.type = 'text/javascript';
  s.src = 'http://api.microsofttranslator.com/V2/Ajax.svc/Translate?oncomplete=bingCallback&appId=' +
    app_id + '&from=' + from_language + '&to=' + to_language + '&text=' + text;
  document.getElementsByTagName("head")[0].appendChild(s);
}

function checkErrors() {
  var errors = []
  $$('.translation-error').each(function(item) {
    item.removeClassName("translation-error")
    item.select('.error-text')[0].innerHTML = ""
  });
  $$('.single-translation').each(function(item) {
    var val = item.select('.edit-field')[0].value
    if (!val.blank()) {
      var patt1 = /%\{[^\{\}]*\}/g;
      var val_subs = val.match(patt1)
      var key = item.select('.translation-text')[0].innerHTML
      var key_subs = key.match(patt1)
      if (val_subs == null) {
        val_subs = []
      }
      if (key_subs == null) {
        key_subs = []
      }
      if (val_subs.sort().join('') != key_subs.sort().join('')) {
        missing_subs = key_subs.diff(val_subs)
        item.addClassName("translation-error");
        errors.push(item)
        item.select('.error-text')[0].innerHTML = "Missing substitution strings: " + missing_subs.join(', ')
      }
    }
  });
  return errors
}

function testAndSave() {
  var errors = checkErrors()

  if (errors.length == 0) {
    document.forms["translate_form"].submit();
  } else {
    console.log(errors);
    alert("Some translations have errors. Please review and correct errors before saving.")
  }
}
/*
prototypeUtils.js from http://jehiah.com/
Licensed under Creative Commons.
version 1.0 December 20 2005
Contains:
+ Form.Element.setValue()
+ unpackToForm()
*/
/* Form.Element.setValue("fieldname/id","valueToSet") */
Form.Element.setValue = function(element, newValue) {
  element_id = element;
  element = $(element);
  if (!element) {
    element = document.getElementsByName(element_id)[0];
  }
  if (!element) {
    return false;
  }
  var method = element.tagName.toLowerCase();
  var parameter = Form.Element.SetSerializers[method](element, newValue);
}
Form.Element.SetSerializers = {
  input: function(element, newValue) {
    switch (element.type.toLowerCase()) {
      case 'submit':
      case 'hidden':
      case 'password':
      case 'text':
        return Form.Element.SetSerializers.textarea(element, newValue);
      case 'checkbox':
      case 'radio':
        return Form.Element.SetSerializers.inputSelector(element, newValue);
    }
    return false;
  },
  inputSelector: function(element, newValue) {
    fields = document.getElementsByName(element.name);
    for (var i = 0; i < fields.length; i++) {
      if (fields[i].value == newValue) {
        fields[i].checked = true;
      }
    }
  },
  textarea: function(element, newValue) {
    element.value = newValue;
  },
  select: function(element, newValue) {
    var value = '',
      opt, index = element.selectedIndex;
    for (var i = 0; i < element.options.length; i++) {
      if (element.options[i].value == newValue) {
        element.selectedIndex = i;
        return true;
      }
    }
  }
}

function unpackToForm(data) {
  for (i in data) {
    Form.Element.setValue(i, data[i].toString());
  }
}
onload = function() {
  $$("div.translation input, div.translation textarea").each(function(e) {
    Event.observe(e, 'focus', function(elm) {
      this.up(".single-translation").down(".translation-text").addClassName("focus-text");
      this.up(".translation").addClassName("selected");
    });
    Event.observe(e, 'blur', function(elm, e) {
      this.up(".single-translation").down(".translation-text").removeClassName("focus-text");
      this.up(".translation").removeClassName("selected");
    });
  });
  checkErrors()
}
