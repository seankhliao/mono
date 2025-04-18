# h1: stylesheet test

## h2: subtitle

### _h3_ an **example** **_title_**

#### _h4_ an **example** **_title_**

##### _h5_ an **example** **_title_**

###### _h6_ an **example** **_title_**

###### title with custom id {#custom-id}

Plain text [a link](./) `inline code` ~~strike text~~

_Emphasis text [a link](./) `inline code` ~~strike text~~_

**Bold text [a link](./) `inline code` ~~strike text~~**

**_Bold and emphasis [a link](./) `inline code` ~~strike text~~_**

```
plain code
```

```go
fmt.Println("highlighted code")
```

> quoted text [a link](./) `inline code` ~~strike text~~
>
> > nested quoted text [a link](./) `inline code` ~~strike text~~
> >
> > > very nested quoted text [a link](./) `inline code` ~~strike text~~
>
> ```
> quoted code fence
> ```
>
> ###### quoted title
>
> more quoted text

| this     | _is_       | **a**    | **_table_**  |
| -------- | ---------- | -------- | ------------ |
| some     | table      | rows     | [a link](./) |
| **bold** | _emphasis_ | `inline` | ~~strike~~   |

1. some
2. numbered
3. list
4. items
5. **bold**
6. _emphasis_
7. [a link](./)
8. `inline code`
9. ~~strike text~~

- some
- unordered
- list
- items
- **bold**
- _emphasis_
- [a link](./)
- `inline code`
- ~~strike text~~

- [x] some
- [ ] unordered
- [x] list
- [ ] items
- [ ] **bold**
- [ ] _emphasis_
- [ ] [a link](./)
- [ ] `inline code`
- ~~strike text~~

#### _probably_ unimplemented

==highlight text==

definition list 1
: the def

definition list 2
: the def

emoji: :joy:

#### html things

<form>
  <label for=text>text input</label>
  <input type=text id=text name=text placeholder="some input text">

<label for=checkbox>checkbox input</label>
<input type=checkbox id=checkbox name=checkbox>

<label for=color>color input</label>
<input type=color id=color name=color>

<label for=email>email input</label>
<input type=email id=email name=email>

<label for=file>file input</label>
<input type=file id=file name=file>

<label for=image>image input</label>
<input type=image id=image name=image>

<label for=number>number input</label>
<input type=number id=number name=number>

<label for=password>password input</label>
<input type=password id=password name=password>

<label for=radio>radio input</label>
<input type=radio id=radio name=radio>

<label for=range>range input</label>
<input type=range id=range name=range>

<label for=search>search input</label>
<input type=search id=search name=search>

<label for=tel>tel input</label>
<input type=tel id=tel name=tel>

<label for=url>url input</label>
<input type=url id=url name=url>

<label for=textarea>textarea input</label>
<textarea id=textarea name=textarea>
Some textarea text
</textarea>

<select id=select>
<option value=1>option 1</option>
<option value=2>option 2</option>
<option value=3>option 3</option>
<optgroup label="some optgroup">
<option value=4>option 4</option>
<option value=5>option 5</option>
</optgroup>
</select>

<fieldset>
<legend>a fieldset</legend>

<label for=date>date input</label>
<input type=date id=date name=date>

<label for=time>time input</label>
<input type=time id=time name=time>

<label for=datetime-local>datetime-local</input>
<input type=datetime-local id=datetime-local name=datetime-local>

<label for=month>month input</label>
<input type=month id=month name=month>

<label for=week>week input</label>
<input type=week id=week name=week>

</fieldset>

<button type=button>a button</button>
<label for=reset>reset input</label>
<input type=reset id=reset name=reset>
<label for=submit>submit input</label>
<input type=submit id=submit name=submit>

<label for=text-datalist>text input with datalist</label>
<input type=text list=datalist id=text-datalist name=text-datalist>
<datalist id=datalist>

  <option value=1>option 1</option>
  <option value=2>option 2</option>
  <option value=3>option 3</option>
</datalist>

</form>
